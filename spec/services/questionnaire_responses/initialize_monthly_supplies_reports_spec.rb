require "rails_helper"

RSpec.describe QuestionnaireResponses::InitializeMonthlySuppliesReports do
  let(:monthly_supplies_reports) { Questionnaire.questionnaire_types[:monthly_supplies_reports] }
  let(:facility) { create(:facility) }
  let(:questionnaire) { create(:questionnaire, :active, questionnaire_type: monthly_supplies_reports) }

  before :each do
    Flipper.enable(:monthly_supplies_reports)
    facility
    questionnaire
  end

  describe "#call" do
    it "should initialize monthly supplies reports for previous month" do
      QuestionnaireResponses::InitializeMonthlySuppliesReports.call
      date = 1.month.ago.beginning_of_month
      questionnaire_response = QuestionnaireResponse.find_by_facility_id(facility)
      expect(questionnaire_response.content).to eq(
        {"month_date" => date.strftime("%Y-%m-%d"), "submitted" => false}
      )
      expect(questionnaire_response.device_created_at).to eq(date)
      expect(questionnaire_response.device_updated_at).to eq(date)
    end

    it "ignores existing monthly supplies reports" do
      existing_content = {"month_date" => 1.months.ago.beginning_of_month.strftime("%Y-%m-%d")}
      existing_monthly_supplies_report = create(:questionnaire_response, questionnaire: questionnaire, facility: facility, content: existing_content)

      QuestionnaireResponses::InitializeMonthlySuppliesReports.call

      expect(QuestionnaireResponse.where(facility: facility).count).to eq(1)
      expect(QuestionnaireResponse.find_by_facility_id(facility)).to eq(existing_monthly_supplies_report)
    end

    it "overrides date when provided as an argument" do
      three_months_ago = 3.months.ago

      QuestionnaireResponses::InitializeMonthlySuppliesReports.call(three_months_ago)

      expect(QuestionnaireResponse.find_by_facility_id(facility).content).to eq(
        {"month_date" => three_months_ago.beginning_of_month.strftime("%Y-%m-%d"), "submitted" => false}
      )
    end
  end

  describe "#latest_active_supplies_reports_questionnaire" do
    it "returns latest active questionnaire" do
      _questionnaire_lower_version = create(:questionnaire, :active, dsl_version: "1", questionnaire_type: monthly_supplies_reports)

      expect(QuestionnaireResponses::InitializeMonthlySuppliesReports.latest_active_supplies_reports_questionnaire)
        .to eq(questionnaire)
    end
  end

  describe "#monthly_supplies_report_exists?" do
    it "only checks for questionnaire responses of type monthly_supplies_reports" do
      screening_questionnaire = create(:questionnaire)
      month_date_str = Time.now.beginning_of_month.strftime("%Y-%m-%d")

      screening_content = {"month_date" => month_date_str}
      create(:questionnaire_response, questionnaire: screening_questionnaire, facility: facility, content: screening_content)

      supplies_report_exists = QuestionnaireResponses::InitializeMonthlySuppliesReports.monthly_supplies_report_exists?(facility.id, month_date_str)

      expect(supplies_report_exists).to be false
    end
  end
end
