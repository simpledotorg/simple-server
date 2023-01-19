require "rails_helper"
require "tasks/scripts/pre_fill_monthly_screening_reports"

RSpec.describe PreFillMonthlyScreeningReports do
  let(:user) { create(:user) }
  let(:facility) { create(:facility) }
  let(:month_date) { Time.now.beginning_of_month - 1.month }

  before :each do
    Flipper.enable(:monthly_screening_reports)

    @questionnaire_types = stub_questionnaire_types
    create(:questionnaire, :active)

    one_month_ago = 1.month.ago
    two_months_ago = 2.months.ago
    patient_1 = create(:patient, :hypertension, recorded_at: two_months_ago, gender: :female, registration_user: user, registration_facility: facility)
    create(:appointment, patient: patient_1, user: user, facility: facility, recorded_at: one_month_ago)
    refresh_views
  end

  describe "#call" do
    it "pre-fills monthly screening reports for previous month" do
      PreFillMonthlyScreeningReports.call

      date = 1.month.ago
      expect(QuestionnaireResponse.find_by_facility_id(facility).content).to eq(
        {
          "month_string" => date.strftime("%Y-%m"),
          "submitted" => false,
          "monthly_screening_reports.diagnosed_cases_on_follow_up_htn.male" => 0,
          "monthly_screening_reports.diagnosed_cases_on_follow_up_htn.female" => 1,
          "monthly_screening_reports.diagnosed_cases_on_follow_up_dm.male" => 0,
          "monthly_screening_reports.diagnosed_cases_on_follow_up_dm.female" => 0,
          "monthly_screening_reports.diagnosed_cases_on_follow_up_htn_and_dm.male" => 0,
          "monthly_screening_reports.diagnosed_cases_on_follow_up_htn_and_dm.female" => 0
        }
      )
    end

    it "ignores existing monthly screening reports" do
      existing_content = {"month_string" => month_date.strftime("%Y-%m")}
      existing_monthly_screening_report = create(:questionnaire_response, facility: facility, content: existing_content)

      PreFillMonthlyScreeningReports.call

      expect(QuestionnaireResponse.where(facility: facility).count).to eq(1)
      expect(QuestionnaireResponse.find_by_facility_id(facility)).to eq(existing_monthly_screening_report)
    end

    it "links pre-filled reports to latest active questionnaire" do
      create(:questionnaire, :active, dsl_version: 2)
      latest_questionnaire = create(:questionnaire, :active, dsl_version: 3)

      PreFillMonthlyScreeningReports.call

      expect(QuestionnaireResponse.find_by_facility_id(facility).questionnaire).to eq(latest_questionnaire)
    end

    it "ignores non-monthly screening reports for idempotency check" do
      questionnaire = create(:questionnaire, questionnaire_type: @questionnaire_types[1])
      existing_content = {"month_string" => month_date.strftime("%Y-%m")}
      create(:questionnaire_response, questionnaire: questionnaire, facility: facility, content: existing_content)
      expect(QuestionnaireResponse.where(facility: facility).count).to eq(1)

      PreFillMonthlyScreeningReports.call

      expect(QuestionnaireResponse.where(facility: facility).count).to eq(2)
      expect(QuestionnaireResponse.where(facility: facility).merge(Questionnaire.monthly_screening_reports).joins(:questionnaire).count).to eq(1)
    end

    it "overrides date when provided as an argument" do
      three_months_ago = 3.months.ago
      four_months_ago = 4.months.ago
      patient_1 = create(:patient, :hypertension, recorded_at: four_months_ago, gender: :male, registration_user: user, registration_facility: facility)
      create(:appointment, patient: patient_1, user: user, facility: facility, recorded_at: three_months_ago)
      refresh_views

      date = three_months_ago
      PreFillMonthlyScreeningReports.call(date)

      expect(QuestionnaireResponse.find_by_facility_id(facility).content).to eq(
        {
          "month_string" => date.strftime("%Y-%m"),
          "submitted" => false,
          "monthly_screening_reports.diagnosed_cases_on_follow_up_htn.male" => 1,
          "monthly_screening_reports.diagnosed_cases_on_follow_up_htn.female" => 0,
          "monthly_screening_reports.diagnosed_cases_on_follow_up_dm.male" => 0,
          "monthly_screening_reports.diagnosed_cases_on_follow_up_dm.female" => 0,
          "monthly_screening_reports.diagnosed_cases_on_follow_up_htn_and_dm.male" => 0,
          "monthly_screening_reports.diagnosed_cases_on_follow_up_htn_and_dm.female" => 0
        }
      )
    end
  end
end
