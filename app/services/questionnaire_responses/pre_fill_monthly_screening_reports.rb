class QuestionnaireResponses::PreFillMonthlyScreeningReports
  def self.call(date = 1.month.ago)
    return unless Flipper.enabled?(:monthly_screening_reports)

    month_date = date.beginning_of_month
    month_date_str = month_date.strftime("%Y-%m-%d")
    facility_reports = monthly_followup_and_registration(month_date_str)

    reports_exist = false
    questionnaire = Questionnaire.monthly_screening_reports.active.order(:dsl_version).last
    facility_reports.each do |facility_report|
      if monthly_screening_report_exists?(facility_report.facility_id, month_date_str)
        reports_exist = true
      else
        QuestionnaireResponse.create!(
          questionnaire_id: questionnaire.id,
          facility_id: facility_report.facility_id,
          content: prefilled_responses(month_date_str, facility_report),
          device_created_at: month_date,
          device_updated_at: month_date
        )
      end
    end

    if reports_exist
      Rails.logger.error("Some/all monthly screening reports already existed during pre-fill task for month: %s" % month_date_str)
    end
  end

  private_class_method

  def self.monthly_followup_and_registration(month_date_str)
    Reports::FacilityMonthlyFollowUpAndRegistration.where(
      month_date: month_date_str
    ).select(
      "facility_id",
      "monthly_follow_ups_htn_all",
      "monthly_follow_ups_htn_male",
      "monthly_follow_ups_htn_female",
      "monthly_follow_ups_dm_all",
      "monthly_follow_ups_dm_male",
      "monthly_follow_ups_dm_female",
      "monthly_follow_ups_htn_and_dm_male",
      "monthly_follow_ups_htn_and_dm_female"
    ).load
  end

  def self.monthly_screening_report_exists?(facility_id, month_date_str)
    QuestionnaireResponse
      .where(facility_id: facility_id)
      .joins(:questionnaire)
      .merge(Questionnaire.monthly_screening_reports)
      .where("content->>'month_date' = ?", month_date_str)
      .any?
  end

  def self.prefilled_responses(month_date_str, facility_report)
    content = {
      "month_date" => month_date_str,
      "submitted" => false
    }
    case Rails.application.config.country[:name]
    when CountryConfig::CONFIGS[:IN]["name"]
      content.merge(
        {
          "monthly_screening_report.diagnosed_cases_on_follow_up_htn.male" => facility_report.monthly_follow_ups_htn_male,
          "monthly_screening_report.diagnosed_cases_on_follow_up_htn.female" => facility_report.monthly_follow_ups_htn_female,
          "monthly_screening_report.diagnosed_cases_on_follow_up_dm.male" => facility_report.monthly_follow_ups_dm_male,
          "monthly_screening_report.diagnosed_cases_on_follow_up_dm.female" => facility_report.monthly_follow_ups_dm_female,
          "monthly_screening_report.diagnosed_cases_on_follow_up_htn_and_dm.male" => facility_report.monthly_follow_ups_htn_and_dm_male,
          "monthly_screening_report.diagnosed_cases_on_follow_up_htn_and_dm.female" => facility_report.monthly_follow_ups_htn_and_dm_female
        }
      )

    when CountryConfig::CONFIGS[:ET]["name"]
      content.merge(
        {
          "monthly_screening_report.total_htn_diagnosed" => facility_report.monthly_follow_ups_htn_all,
          "monthly_screening_report.total_dm_diagnosed" => facility_report.monthly_follow_ups_dm_all
        }
      )
    else
      content
    end
  end
end
