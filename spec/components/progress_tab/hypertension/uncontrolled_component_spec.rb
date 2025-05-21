require "rails_helper"

RSpec.describe ProgressTab::Hypertension::UncontrolledComponent, type: :component do
  let(:region) { double("Region", name: "Region 1") }

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

  let(:uncontrolled) { map_data(uncontrolled_data) }
  let(:adjusted_patients) { map_data(adjusted_patients_data) }
  let(:uncontrolled_rates) { map_data(uncontrolled_rates_data) }
  let(:period_info) { map_data(period_info_data) }

  def map_data(data)
    data.map { |date_str, value| [Period.new(type: :month, value: date_str), value] }.to_h
  end

  def render_component
    render_inline(ProgressTab::Hypertension::UncontrolledComponent.new(
      uncontrolled_rates: uncontrolled_rates,
      uncontrolled: uncontrolled,
      adjusted_patients: adjusted_patients,
      period_info: period_info,
      region: region
    ))
  end

  context "when rendering the component" do
    before do
      render_component
    end

    it "renders the correct title text" do
      expect(page).to have_text(I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.hypertension_uncontrolled_short"))
    end

    it "renders the correct subtitle text" do
      expect(page).to have_text(I18n.t("progress_tab.diagnosis_report.patient_treatment_outcomes.uncontrolled_card.subtitle",
        facility_name: "Region 1", diagnosis: "Hypertension",
        uncontrolled_threshold: I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.hypertension_uncontrolled_long")))
    end

    it "renders the tooltip with correct numerator and denominator text" do
      expect(page).to have_text(I18n.t("progress_tab.diagnosis_report.patient_treatment_outcomes.uncontrolled_card.help_tooltip.numerator",
        uncontrolled_threshold: I18n.t("progress_tab.diagnosis_report.diagnosis_thresholds.hypertension_uncontrolled_long")))
      expect(page).to have_text(I18n.t("progress_tab.diagnosis_report.patient_treatment_outcomes.uncontrolled_card.help_tooltip.denominator",
        facility_name: "Region 1", diagnosis: "Hypertension"))
    end

    it "renders the bar chart with correct data" do
      expect(page).to have_selector("[data-graph-type='bar-chart']")
    end

    it "includes the correct graph colors" do
      expect(page).to have_selector(".bgc-yellow-dark-new")
    end
  end
end
