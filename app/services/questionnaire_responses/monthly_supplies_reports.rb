class QuestionnaireResponses::MonthlySuppliesReports
  def initialize(date = 1.month.ago)
    @month_date = date.beginning_of_month
    @facility_ids = Facility.select("id").pluck(:id)
    @questionnaire_id = latest_active_supplies_reports_questionnaire_id
  end

  def seed
    @facility_ids.each do |facility_id|
      unless monthly_supplies_report_exists?(facility_id)
        QuestionnaireResponse.create!(
          questionnaire_id: @questionnaire_id,
          facility_id: facility_id,
          content: supplies_report_content,
          device_created_at: @month_date,
          device_updated_at: @month_date
        )
      end
    end
  end

  def latest_active_supplies_reports_questionnaire_id
    Questionnaire.monthly_supplies_reports.active.order(dsl_version: :desc).first.id
  end

  def monthly_supplies_report_exists?(facility_id)
    QuestionnaireResponse
      .where(facility_id: facility_id)
      .joins(:questionnaire)
      .merge(Questionnaire.monthly_supplies_reports)
      .where("content->>'month_date' = ?", month_date_str)
      .any?
  end

  def supplies_report_content
    {
      "month_date" => month_date_str,
      "submitted" => false
    }
  end

  private

  def month_date_str
    @month_date.strftime("%Y-%m-%d")
  end
end
