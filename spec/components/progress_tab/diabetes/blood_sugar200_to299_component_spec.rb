require "rails_helper"

RSpec.describe ProgressTab::Diabetes::BloodSugar200To299Component, type: :component do
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

  def render_component_with(use_who_standard: nil)
    render_inline(ProgressTab::Diabetes::BloodSugar200To299Component.new(
      uncontrolled_rates: uncontrolled_rates,
      uncontrolled: uncontrolled,
      adjusted_patients: adjusted_patients,
      period_info: period_info,
      region: region,
      use_who_standard: use_who_standard
    ))
  end

  context "when the country is Sri Lanka" do
    before do
      render_component_with(use_who_standard: true)
    end

    it "renders the correct uncontrolled threshold long text for Sri Lanka" do
      expect(rendered_component).to have_text(I18n.t("bs_over_200_copy.reports_card_title_dm_fbs"))
    end

    it "renders the correct uncontrolled threshold short text for Sri Lanka" do
      expect(rendered_component).to have_text(I18n.t("bs_over_200_copy.bs_200_to_299.title_dm_fbs"))
    end

    it "renders the correct denominator text for Sri Lanka" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.patient_treatment_outcomes.uncontrolled_card.help_tooltip.denominator", facility_name: "Region 1", diagnosis: "Diabetes"))
    end

    it "renders the bar chart with correct data" do
      expect(rendered_component).to have_selector('.d-flex[data-graph-type="bar-chart"]')
      expect(rendered_component).to have_selector(".w-32px.bgc-yellow")
    end

    it "renders the correct uncontrolled bar text for Sri Lanka" do
      expect(rendered_component).to have_text(I18n.t("bs_over_200_copy.bs_200_to_299.title_dm_fbs"))
    end
  end

  context "when the country is not Sri Lanka" do
    before do
      render_component_with(use_who_standard: false)
    end

    it "renders the correct uncontrolled threshold long text for non-Sri Lanka countries" do
      expect(rendered_component).to have_text(I18n.t("bs_over_200_copy.reports_card_title_dm"))
    end

    it "renders the correct uncontrolled threshold short text for non-Sri Lanka countries" do
      expect(rendered_component).to have_text(I18n.t("bs_over_200_copy.bs_200_to_299.title_dm_bs"))
    end

    it "renders the correct denominator text for non-Sri Lanka countries" do
      expect(rendered_component).to have_text(I18n.t("progress_tab.diagnosis_report.patient_treatment_outcomes.uncontrolled_card.help_tooltip.denominator", facility_name: "Region 1", diagnosis: "Diabetes"))
    end

    it "renders the bar chart with correct data for non-Sri Lanka countries" do
      expect(rendered_component).to have_selector('.d-flex[data-graph-type="bar-chart"]')
      expect(rendered_component).to have_selector(".w-32px.bgc-yellow")
    end

    it "renders the correct uncontrolled bar text for non-Sri Lanka countries" do
      expect(rendered_component).to have_text(I18n.t("bs_over_200_copy.bs_200_to_299.title_dm"))
    end
  end
end
