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

  def render_component_with(use_who_standard: nil)
    render_inline(ProgressTab::Diabetes::ControlComponent.new(
      controlled_rates: controlled_rates,
      controlled: controlled,
      adjusted_patients: adjusted_patients,
      period_info: period_info,
      region: region,
      use_who_standard: use_who_standard
    ))
  end

  context "when WHO standard is used (Sri Lanka)" do
    before do
      render_component_with(use_who_standard: true)
    end

    it "renders the controlled threshold long text for WHO standard" do
      expect(rendered_component).to have_text("Numerator: Patients with FBS <126mg/dL or HbA1c <7% at their last visit in the last 3 months")
    end

    it "renders the controlled threshold short text for WHO standard" do
      expect(rendered_component).to have_text(I18n.t("bs_below_200_copy.reports_card_title_dm_fbs"))
    end

    it "renders the correct subtitle for WHO standard" do
      expect(rendered_component).to have_text(I18n.t(
        "bs_below_200_copy.reports_card_subtitle_dm_fbs",
        region_name: "Region 1",
        diagnosis: "Diabetes",
        controlled_threshold: I18n.t("bs_below_200_copy.numerator_fbs")
      ))
    end

    it "renders the bar chart with correct data" do
      expect(rendered_component).to have_selector('.d-flex[data-graph-type="bar-chart"]')
      expect(rendered_component).to have_selector(".w-32px.bgc-green-dark-new", count: 3)
    end
  end

  context "when WHO standard is not used (other countries)" do
    before do
      render_component_with(use_who_standard: false)
    end

    it "renders the controlled threshold long text for non-WHO standard" do
      expect(rendered_component).to have_text(I18n.t("bs_below_200_copy.numerator"))
    end

    it "renders the controlled threshold short text for non-WHO standard" do
      expect(rendered_component).to have_text(I18n.t("bs_below_200_copy.reports_card_title_dm_bs"))
    end

    it "renders the correct subtitle for non-WHO standard" do
      expect(rendered_component).to have_text(I18n.t(
        "bs_below_200_copy.reports_card_subtitle_dm",
        region_name: "Region 1",
        diagnosis: "Diabetes",
        controlled_threshold: I18n.t("bs_below_200_copy.numerator")
      ))
    end

    it "renders the bar chart with correct data" do
      expect(rendered_component).to have_selector('.d-flex[data-graph-type="bar-chart"]')
      expect(rendered_component).to have_selector(".w-32px.bgc-green-dark-new", count: 3)
    end
  end
end
