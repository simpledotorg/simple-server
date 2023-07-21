require "rails_helper"

RSpec.describe QuestionnaireResponses::DrugStockReports do
  let(:drug_stock_reports) { Questionnaire.questionnaire_types[:drug_stock_reports] }
  let(:facility) { create(:facility) }
  let(:questionnaire) { create(:questionnaire, :active, questionnaire_type: drug_stock_reports) }

  before :each do
    Flipper.enable(:drug_stock_questionnaires)
    facility
    questionnaire
  end

  describe "#seed" do
    it "should initialize drug stock reports for previous month" do
      QuestionnaireResponses::DrugStockReports.new.seed
      date = 1.month.ago.beginning_of_month
      questionnaire_response = QuestionnaireResponse.find_by_facility_id(facility)
      expect(questionnaire_response.content).to eq(
        {"month_date" => date.strftime("%Y-%m-%d"), "submitted" => false}
      )
      expect(questionnaire_response.device_created_at).to eq(date)
      expect(questionnaire_response.device_updated_at).to eq(date)
    end

    it "ignores existing drug stock reports" do
      existing_content = {"month_date" => 1.months.ago.beginning_of_month.strftime("%Y-%m-%d")}
      existing_drug_stock_report = create(:questionnaire_response, questionnaire: questionnaire, facility: facility, content: existing_content)

      QuestionnaireResponses::DrugStockReports.new.seed

      expect(QuestionnaireResponse.where(facility: facility).count).to eq(1)
      expect(QuestionnaireResponse.find_by_facility_id(facility)).to eq(existing_drug_stock_report)
    end

    it "overrides date when provided as an argument" do
      three_months_ago = 3.months.ago

      QuestionnaireResponses::DrugStockReports.new(three_months_ago).seed

      expected_content = {
        "month_date" => three_months_ago.beginning_of_month.strftime("%Y-%m-%d"),
        "submitted" => false
      }
      expect(QuestionnaireResponse.find_by_facility_id(facility).content).to eq(expected_content)
    end
  end

  describe "#drug_stock_report_exists?" do
    it "only checks for questionnaire responses of type drug_stock_reports" do
      drug_stock_questionnaire = create(:questionnaire)
      date = Time.now.beginning_of_month

      screening_content = {"month_date" => date.strftime("%Y-%m-%d")}
      create(:questionnaire_response, questionnaire: drug_stock_questionnaire, facility: facility, content: screening_content)

      drug_stock_report_exists = QuestionnaireResponses::DrugStockReports.new(date).drug_stock_report_exists?(facility.id)

      expect(drug_stock_report_exists).to be false
    end
  end
end
