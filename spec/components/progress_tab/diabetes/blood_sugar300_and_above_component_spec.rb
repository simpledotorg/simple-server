require "rails_helper"

RSpec.describe ProgressTab::Diabetes::BloodSugar300AndAboveComponent, type: :component do
  let(:region) { double("Region", name: "Region 1") }

  # Data for the last three months: Aug, Sept, and Oct
  let(:uncontrolled_data) do
    {
      "2024-08-01" => 20,
      "2024-09-01" => 25,
      "2024-10-01" => 30
    }
  end

  let(:adjusted_patients_data) do
    {
      "2024-08-01" => 140,
      "2024-09-01" => 150,
      "2024-10-01" => 160
    }
  end

  let(:uncontrolled_rates_data) do
    {
      "2024-08-01" => 0.14,
      "2024-09-01" => 0.17,
      "2024-10-01" => 0.19
    }
  end

  let(:period_info_data) do
    {
      "2024-08-01" => {name: "Aug-2024"},
      "2024-09-01" => {name: "Sep-2024"},
      "2024-10-01" => {name: "Oct-2024"}
    }
  end

  # Mapping data for the component to use
  let(:uncontrolled) { map_data(uncontrolled_data) }
  let(:adjusted_patients) { map_data(adjusted_patients_data) }
  let(:uncontrolled_rates) { map_data(uncontrolled_rates_data) }
  let(:period_info) { map_data(period_info_data) }

  def map_data(data)
    data.map { |date_str, value| [Period.new(type: :month, value: date_str), value] }.to_h
  end

  context "when the country is Sri Lanka" do
    before do
      allow(CountryConfig).to receive(:current_country?).with("Sri Lanka").and_return(true)
      render_inline(ProgressTab::Diabetes::BloodSugar300AndAboveComponent.new(
        uncontrolled_rates: uncontrolled_rates,
        uncontrolled: uncontrolled,
        adjusted_patients: adjusted_patients,
        period_info: period_info,
        region: region
      ))
    end

    it "renders the correct uncontrolled threshold long text for Sri Lanka" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.lk_diabetes_very_uncontrolled_long"))
    end

    it "renders the correct uncontrolled threshold short text for Sri Lanka" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.lk_diabetes_very_uncontrolled_short"))
    end

    it "renders the correct denominator text for Sri Lanka" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.patient_treatment_outcomes.very_uncontrolled_card.help_tooltip.denominator", facility_name: "Region 1", diagnosis: "Diabetes"))
    end

    it "renders the bar chart with correct data" do
      expect(rendered_component).to have_selector('.d-flex[data-graph-type="bar-chart"]')
      expect(rendered_component).to have_selector(".w-32px.bgc-yellow-dark-new")
    end

    it "renders the correct uncontrolled bar text for Sri Lanka" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.lk_diabetes_very_uncontrolled_bar"))
    end
  end

  context "when the country is not Sri Lanka" do
    before do
      allow(CountryConfig).to receive(:current_country?).with("Sri Lanka").and_return(false)
      render_inline(ProgressTab::Diabetes::BloodSugar300AndAboveComponent.new(
        uncontrolled_rates: uncontrolled_rates,
        uncontrolled: uncontrolled,
        adjusted_patients: adjusted_patients,
        period_info: period_info,
        region: region
      ))
    end

    it "renders the correct uncontrolled threshold long text for non-Sri Lanka countries" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.diabetes_very_uncontrolled_long"))
    end

    it "renders the correct uncontrolled threshold short text for non-Sri Lanka countries" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.diabetes_very_uncontrolled_short"))
    end

    it "renders the correct denominator text for non-Sri Lanka countries" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.patient_treatment_outcomes.very_uncontrolled_card.help_tooltip.denominator", facility_name: "Region 1", diagnosis: "Diabetes"))
    end

    it "renders the bar chart with correct data for non-Sri Lanka countries" do
      expect(rendered_component).to have_selector('.d-flex[data-graph-type="bar-chart"]')
      expect(rendered_component).to have_selector(".w-32px.bgc-yellow-dark-new")
    end

    it "renders the correct uncontrolled bar text for non-Sri Lanka countries" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.diabetes_very_uncontrolled_bar"))
    end
  end
end
