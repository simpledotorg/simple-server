class QuestionnaireResponses::DrugStockReports
  include QuestionnaireResponsesHelper

  def initialize(date = 1.month.ago)
    @month_date = date.beginning_of_month
    @facility_ids = Facility.select("id").pluck(:id)
    @questionnaire_id = latest_active_questionnaire_id(Questionnaire.questionnaire_types[:drug_stock_reports])
  end

  def seed
    @facility_ids.each do |facility_id|
      unless drug_stock_report_exists?(facility_id)
        QuestionnaireResponse.create!(
          questionnaire_id: @questionnaire_id,
          facility_id: facility_id,
          content: monthly_reports_base_content,
          device_created_at: @month_date,
          device_updated_at: @month_date
        )
      end
    end
  end

  def drug_stock_report_exists?(facility_id)
    QuestionnaireResponse
      .where(facility_id: facility_id)
      .joins(:questionnaire)
      .merge(Questionnaire.drug_stock_reports)
      .where("content->>'month_date' = ?", month_date_str)
      .any?
  end
end
