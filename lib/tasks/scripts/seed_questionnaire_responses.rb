class SeedQuestionnaireResponses
  def self.call
    return unless Flipper.enabled?(:monthly_screening_reports)

    facility_reports =
      Reports::FacilityMonthlyFollowUpAndRegistration.where(
        month_date: Date.current.beginning_of_month
      ).select(
        "monthly_follow_ups_htn_male",
        "monthly_follow_ups_htn_female",
        "monthly_follow_ups_dm_male",
        "monthly_follow_ups_dm_female",
        "monthly_follow_ups_htn_and_dm_male",
        "monthly_follow_ups_htn_and_dm_female"
      ).load

    Questionnaire.monthly_screening_reports.active.product(facility_reports).each do |questionnaire, facility_report|
      QuestionnaireResponse.create!(
        questionnaire: questionnaire.id,
        facility_id: facility_report.facility_id,
        user_id: nil,
        content: {**prefilled_responses(facility_report)},
        device_created_at: Time.now,
        device_updated_at: Time.now
      )
    end
  end

  private

  def prefilled_responses(facility_report)
    {
      "diagnosed_cases_on_follow_up_htn.male" => facility_report.monthly_follow_ups_htn_male,
      "diagnosed_cases_on_follow_up_htn.female" => facility_report.monthly_follow_ups_htn_female,
      "diagnosed_cases_on_follow_up_dm.male" => facility_report.monthly_follow_ups_dm_male,
      "diagnosed_cases_on_follow_up_dm.female" => facility_report.monthly_follow_ups_dm_female,
      "diagnosed_cases_on_follow_up_htn_and_dm.male" => facility_report.monthly_follow_ups_htn_and_dm_male,
      "diagnosed_cases_on_follow_up_htn_and_dm.female" => facility_report.monthly_follow_ups_htn_and_dm_female
    }
  end
end
