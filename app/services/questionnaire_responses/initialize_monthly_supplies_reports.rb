class QuestionnaireResponses::InitializeMonthlySuppliesReports
  def self.call(date = 1.month.ago)
    return unless Flipper.enabled?(:monthly_supplies_reports)

    month_date = date.beginning_of_month
    month_date_str = month_date.strftime("%Y-%m-%d")
    facility_ids = Facility.select("id").pluck(:id)

    reports_exist = false
    questionnaire = latest_active_supplies_reports_questionnaire

    facility_ids.each do |facility_id|
      if monthly_supplies_report_exists?(facility_id, month_date_str)
        reports_exist = true
      else
        QuestionnaireResponse.create!(
          questionnaire_id: questionnaire.id,
          facility_id: facility_id,
          content: supplies_report_content(month_date_str),
          device_created_at: month_date,
          device_updated_at: month_date
        )
      end
    end

    if reports_exist
      Rails.logger.error("Some/all monthly supplies reports already existed during initialization task for month: %s" % month_date_str)
    end
  end

  def self.latest_active_supplies_reports_questionnaire
    Questionnaire.monthly_supplies_reports.active.order(:dsl_version).last
  end

  def self.monthly_supplies_report_exists?(facility_id, month_date_str)
    QuestionnaireResponse
      .where(facility_id: facility_id)
      .merge(Questionnaire.monthly_supplies_reports)
      .joins(:questionnaire)
      .where("content->>'month_date' = ?", month_date_str)
      .any?
  end

  def self.supplies_report_content(month_date_str)
    {
      "month_date" => month_date_str,
      "submitted" => false
    }
  end
end
