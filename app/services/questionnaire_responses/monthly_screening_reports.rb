class QuestionnaireResponses::MonthlyScreeningReports
  include QuestionnaireResponsesHelper

  def initialize(date = 1.month.ago)
    @month_date = date.beginning_of_month
    @facility_reports = monthly_followup_and_registration
    @questionnaire_id = latest_active_questionnaire_id(Questionnaire.questionnaire_types[:monthly_screening_reports])
  end

  def pre_fill
    @facility_reports.each do |facility_report|
      unless monthly_screening_report_exists?(facility_report.facility_id)
        QuestionnaireResponse.create!(
          questionnaire_id: @questionnaire_id,
          facility_id: facility_report.facility_id,
          content: prefilled_responses(month_date_str, facility_report),
          device_created_at: @month_date,
          device_updated_at: @month_date
        )
      end
    end
  end

  private

  def monthly_followup_and_registration
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

  def monthly_screening_report_exists?(facility_id)
    QuestionnaireResponse
      .where(facility_id: facility_id)
      .joins(:questionnaire)
      .merge(Questionnaire.monthly_screening_reports)
      .where("content->>'month_date' = ?", month_date_str)
      .any?
  end

  def prefilled_responses(month_date_str, facility_report)
    case Rails.application.config.country[:name]
    when CountryConfig::CONFIGS[:IN]["name"]
      {
        **monthly_reports_base_content,
        "monthly_screening_report.diagnosed_cases_on_follow_up_htn.male" => facility_report.monthly_follow_ups_htn_male,
        "monthly_screening_report.diagnosed_cases_on_follow_up_htn.female" => facility_report.monthly_follow_ups_htn_female,
        "monthly_screening_report.diagnosed_cases_on_follow_up_dm.male" => facility_report.monthly_follow_ups_dm_male,
        "monthly_screening_report.diagnosed_cases_on_follow_up_dm.female" => facility_report.monthly_follow_ups_dm_female,
        "monthly_screening_report.diagnosed_cases_on_follow_up_htn_and_dm.male" => facility_report.monthly_follow_ups_htn_and_dm_male,
        "monthly_screening_report.diagnosed_cases_on_follow_up_htn_and_dm.female" => facility_report.monthly_follow_ups_htn_and_dm_female
      }

    when CountryConfig::CONFIGS[:ET]["name"]
      {
        **monthly_reports_base_content,
        "monthly_screening_report.total_htn_diagnosed" => facility_report.monthly_follow_ups_htn_all,
        "monthly_screening_report.total_dm_diagnosed" => facility_report.monthly_follow_ups_dm_all
      }
    else
      monthly_reports_base_content
    end
  end
end
