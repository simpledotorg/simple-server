require "rails_helper"

RSpec.describe ProgressTab::Diabetes::ControlComponent, type: :component do
  let(:region) { double("Region", name: "Region 1") }

  let(:control_data) do
    {
      "2024-08-01" => 85,
      "2024-09-01" => 88,
      "2024-10-01" => 90
    }
  end

  let(:adjusted_patients_data) do
    {
      "2024-08-01" => 140,
      "2024-09-01" => 150,
      "2024-10-01" => 160
    }
  end

  let(:control_rates_data) do
    {
      "2024-08-01" => 0.61,
      "2024-09-01" => 0.59,
      "2024-10-01" => 0.57
    }
  end

  let(:period_info_data) do
    {
      "2024-08-01" => {name: "Aug-2024"},
      "2024-09-01" => {name: "Sep-2024"},
      "2024-10-01" => {name: "Oct-2024"}
    }
  end

  let(:controlled) { map_data(control_data) }
  let(:adjusted_patients) { map_data(adjusted_patients_data) }
  let(:controlled_rates) { map_data(control_rates_data) }
  let(:period_info) { map_data(period_info_data) }

  def map_data(data)
    data.map { |date_str, value| [Period.new(type: :month, value: date_str), value] }.to_h
  end

  context "when the country is Sri Lanka" do
    before do
      allow(CountryConfig).to receive(:current_country?).with("Sri Lanka").and_return(true)
      render_inline(ProgressTab::Diabetes::ControlComponent.new(
        controlled_rates: controlled_rates,
        controlled: controlled,
        adjusted_patients: adjusted_patients,
        period_info: period_info,
        region: region
      ))
    end

    it "renders the correct controlled threshold long text for Sri Lanka" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.lk_diabetes_controlled_long"))
    end

    it "renders the correct controlled threshold short text for Sri Lanka" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.lk_diabetes_controlled_short"))
    end

    it "renders the correct subtitle for Sri Lanka" do
      expect(rendered_component).to have_text(I18n.t(
        "progress_tab.diagnosis_report.patient_treatment_outcomes.controlled_card.subtitle",
        facility_name: "Region 1",
        diagnosis: "Diabetes",
        controlled_threshold: I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.lk_diabetes_controlled_long")
      ))
    end

    it "renders the correct numerator text for Sri Lanka" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.patient_treatment_outcomes.controlled_card.help_tooltip.numerator", controlled_threshold: I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.lk_diabetes_controlled_long")))
    end

    it "renders the correct denominator text for Sri Lanka" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.patient_treatment_outcomes.controlled_card.help_tooltip.denominator", facility_name: "Region 1", diagnosis: "Diabetes"))
    end

    it "renders the bar chart with correct data" do
      expect(rendered_component).to have_selector('.d-flex[data-graph-type="bar-chart"]')
      expect(rendered_component).to have_selector(".w-32px.bgc-green-dark-new", count: 3)
    end

    it "renders the correct controlled bar text for Sri Lanka" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.lk_diabetes_controlled_bar"))
    end
  end

  context "when the country is not Sri Lanka" do
    before do
      allow(CountryConfig).to receive(:current_country?).with("Sri Lanka").and_return(false)
      render_inline(ProgressTab::Diabetes::ControlComponent.new(
        controlled_rates: controlled_rates,
        controlled: controlled,
        adjusted_patients: adjusted_patients,
        period_info: period_info,
        region: region
      ))
    end

    it "renders the correct controlled threshold long text for non-Sri Lanka countries" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.diabetes_controlled_long"))
    end

    it "renders the correct controlled threshold short text for non-Sri Lanka countries" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.diabetes_controlled_short"))
    end

    it "renders the correct subtitle for non-Sri Lanka countries" do
      expect(rendered_component).to have_text(I18n.t(
        "progress_tab.diagnosis_report.patient_treatment_outcomes.controlled_card.subtitle",
        facility_name: "Region 1",
        diagnosis: "Diabetes",
        controlled_threshold: I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.diabetes_controlled_long")
      ))
    end

    it "renders the correct numerator text for non-Sri Lanka countries" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.patient_treatment_outcomes.controlled_card.help_tooltip.numerator", controlled_threshold: I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.diabetes_controlled_long")))
    end

    it "renders the correct denominator text for non-Sri Lanka countries" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.patient_treatment_outcomes.controlled_card.help_tooltip.denominator", facility_name: "Region 1", diagnosis: "Diabetes"))
    end

    it "renders the bar chart with correct data for non-Sri Lanka countries" do
      expect(rendered_component).to have_selector('.d-flex[data-graph-type="bar-chart"]')
      expect(rendered_component).to have_selector(".w-32px.bgc-green-dark-new", count: 3)
    end

    it "renders the correct controlled bar text for non-Sri Lanka countries" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.diabetes_controlled_bar"))
    end
  end
end
