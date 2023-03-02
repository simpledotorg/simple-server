class PreFillMonthlyScreeningReports
  def self.call(date = 1.month.ago)
    return unless Flipper.enabled?(:monthly_screening_reports)

    month_date = date.beginning_of_month
    month_date_str = month_date.strftime("%Y-%m-%d")
    facility_reports = monthly_followup_and_registration(month_date)

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
          device_created_at: Time.now,
          device_updated_at: Time.now
        )
      end
    end

    if reports_exist
      Rails.logger.error("Some/all monthly screening reports already existed during pre-fill task for month: %s" % month_date_str)
    end
  end

  private_class_method

  def self.monthly_followup_and_registration(month_date)
    Reports::FacilityMonthlyFollowUpAndRegistration.where(
      month_date: month_date
    ).select(
      "facility_id",
      "monthly_follow_ups_htn_male",
      "monthly_follow_ups_htn_female",
      "monthly_follow_ups_dm_male",
      "monthly_follow_ups_dm_female",
      "monthly_follow_ups_htn_and_dm_male",
      "monthly_follow_ups_htn_and_dm_female"
    ).load
  end

  def self.monthly_screening_report_exists?(facility_id, month_date)
    QuestionnaireResponse
      .where(facility_id: facility_id)
      .merge(Questionnaire.monthly_screening_reports)
      .joins(:questionnaire)
      .where("content->>'month_date' = ?", month_date)
      .any?
  end

  def self.prefilled_responses(month_date, facility_report)
    {
      "month_date" => month_date,
      "submitted" => false,
      "monthly_screening_reports.diagnosed_cases_on_follow_up_htn.male" => facility_report.monthly_follow_ups_htn_male,
      "monthly_screening_reports.diagnosed_cases_on_follow_up_htn.female" => facility_report.monthly_follow_ups_htn_female,
      "monthly_screening_reports.diagnosed_cases_on_follow_up_dm.male" => facility_report.monthly_follow_ups_dm_male,
      "monthly_screening_reports.diagnosed_cases_on_follow_up_dm.female" => facility_report.monthly_follow_ups_dm_female,
      "monthly_screening_reports.diagnosed_cases_on_follow_up_htn_and_dm.male" => facility_report.monthly_follow_ups_htn_and_dm_male,
      "monthly_screening_reports.diagnosed_cases_on_follow_up_htn_and_dm.female" => facility_report.monthly_follow_ups_htn_and_dm_female
    }
  end
end
