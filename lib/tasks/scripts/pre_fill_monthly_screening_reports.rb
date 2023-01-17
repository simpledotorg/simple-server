class PreFillMonthlyScreeningReports
  def self.call(month_date = Time.now.beginning_of_month - 1.month)
    return unless Flipper.enabled?(:monthly_screening_reports)

    month_string = month_date.strftime("%Y-%m")
    facility_reports =
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

    monthly_screening_reports_clash = false
    questionnaire = Questionnaire.monthly_screening_reports.active.last
    facility_reports.each do |facility_report|
      q = QuestionnaireResponse
        .where(facility_id: facility_report.facility_id)
        .where("content->>'month_string' = ?", month_string)

      if q.empty?
        QuestionnaireResponse.create!(
          questionnaire_id: questionnaire.id,
          facility_id: facility_report.facility_id,
          content: prefilled_responses(month_string, facility_report),
          device_created_at: Time.now,
          device_updated_at: Time.now
        )
      else
        monthly_screening_reports_clash = true
      end
    end

    if monthly_screening_reports_clash
      Rails.logger.error("Clashing monthly reports found during pre-fill task for month: %s" % month_string)
    end
  end

  private

  def self.prefilled_responses(month_string, facility_report)
    {
      "month_string" => month_string,
      "submitted" => false,
      "diagnosed_cases_on_follow_up_htn.male" => facility_report.monthly_follow_ups_htn_male,
      "diagnosed_cases_on_follow_up_htn.female" => facility_report.monthly_follow_ups_htn_female,
      "diagnosed_cases_on_follow_up_dm.male" => facility_report.monthly_follow_ups_dm_male,
      "diagnosed_cases_on_follow_up_dm.female" => facility_report.monthly_follow_ups_dm_female,
      "diagnosed_cases_on_follow_up_htn_and_dm.male" => facility_report.monthly_follow_ups_htn_and_dm_male,
      "diagnosed_cases_on_follow_up_htn_and_dm.female" => facility_report.monthly_follow_ups_htn_and_dm_female
    }
  end
end
