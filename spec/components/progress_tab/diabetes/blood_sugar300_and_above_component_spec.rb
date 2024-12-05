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
      "2024-08-01" => { name: "Aug-2024" },
      "2024-09-01" => { name: "Sep-2024" },
      "2024-10-01" => { name: "Oct-2024" }
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
    render_inline(ProgressTab::Diabetes::BloodSugar300AndAboveComponent.new(
      uncontrolled_rates: uncontrolled_rates,
      uncontrolled: uncontrolled,
      adjusted_patients: adjusted_patients,
      period_info: period_info,
      region: region,
      use_who_standard: use_who_standard
    ))
  end

  describe "Rendering based on country standard" do
    context "when using WHO standard" do
      before do
        render_component_with(use_who_standard: true)
      end

      it "displays the correct uncontrolled threshold long text" do
        expect(rendered_component).to have_text(I18n.t("bs_over_200_copy.bs_over_300.numerator_dm_fbs"))
      end

      it "displays the correct uncontrolled threshold short text" do
        expect(rendered_component).to have_text(I18n.t("bs_over_200_copy.bs_over_300.title_dm_fbs"))
      end

      it "displays the correct denominator text" do
        expect(rendered_component).to have_text(
          I18n.t(
            "progress_tab.diagnosis_report.patient_treatment_outcomes.controlled_card.help_tooltip.denominator",
            facility_name: region.name,
            diagnosis: "Diabetes"
          )
        )
      end

      it "renders the bar chart with correct styling and tooltip enabled" do
        expect(rendered_component).to have_selector('.d-flex[data-graph-type="bar-chart"]')
        expect(rendered_component).to have_selector(".w-32px.bgc-yellow-dark-new")
      end
    end

    context "when not using WHO standard" do
      before do
        render_component_with(use_who_standard: false)
      end

      it "displays the correct uncontrolled threshold short text" do
        expect(rendered_component).to have_text(I18n.t("bs_over_200_copy.bs_over_300.title"))
      end

      it "displays the correct denominator text" do
        expect(rendered_component).to have_text(
          I18n.t(
            "progress_tab.diagnosis_report.patient_treatment_outcomes.controlled_card.help_tooltip.denominator",
            facility_name: region.name,
            diagnosis: "Diabetes"
          )
        )
      end

      it "renders the bar chart with correct styling and tooltip enabled" do
        expect(rendered_component).to have_selector('.d-flex[data-graph-type="bar-chart"]')
        expect(rendered_component).to have_selector(".w-32px.bgc-yellow-dark-new")
      end
    end
  end
end
