require "rails_helper"

RSpec.describe Reports::ProgressMonthlyFollowUpsComponent, type: :component do
  let(:region) { double("Region", name: "Region 1") }
  let(:diagnosis) { "Diabetes" }
  let(:period_info) do
    {
      Period.new(type: :month, value: "2024-06-01") => {name: "Jun-2024", ltfu_since_date: "30-Jun-2023"},
      Period.new(type: :month, value: "2024-07-01") => {name: "Jul-2024", ltfu_since_date: "31-Jul-2023"},
      Period.new(type: :month, value: "2024-08-01") => {name: "Aug-2024", ltfu_since_date: "31-Aug-2023"},
      Period.new(type: :month, value: "2024-09-01") => {name: "Sep-2024", ltfu_since_date: "30-Sep-2023"},
      Period.new(type: :month, value: "2024-10-01") => {name: "Oct-2024", ltfu_since_date: "31-Oct-2023"},
      Period.new(type: :month, value: "2024-11-01") => {name: "Nov-2024", ltfu_since_date: "30-Nov-2023"}
    }
  end
  let(:monthly_follow_ups) do
    {
      Period.new(type: :month, value: "2024-06-01") => 5,
      Period.new(type: :month, value: "2024-07-01") => 4,
      Period.new(type: :month, value: "2024-08-01") => 3,
      Period.new(type: :month, value: "2024-09-01") => 4,
      Period.new(type: :month, value: "2024-10-01") => 11,
      Period.new(type: :month, value: "2024-11-01") => 2
    }
  end

  subject do
    render_inline(described_class.new(
      monthly_follow_ups: monthly_follow_ups,
      period_info: period_info,
      region: region,
      diagnosis: diagnosis
    ))
  end

  describe "rendering the component" do
    it "renders the title correctly" do
      expect(subject).to have_css("h2", text: I18n.t("progress_tab.diagnosis_report.monthly_follow_up_patients.title"))
    end

    it "renders the subtitle with correct facility name and diagnosis" do
      expect(subject).to have_selector("p", text: I18n.t("progress_tab.diagnosis_report.monthly_follow_up_patients.subtitle", facility_name: region.name, diagnosis: diagnosis))
    end

    it "displays the correct number of total registrations" do
      total_values = monthly_follow_ups.values
      total_values.each do |value|
        expect(subject).to have_text(value.to_s)
      end
    end

    it "passes the correct data to the data bar graph partial" do
      expect(subject).to have_selector('div[data-graph-type="bar-chart"]')
      expect(subject).to have_text("5")
      expect(subject).to have_text("4")
      expect(subject).to have_text("3")
      expect(subject).to have_text("4")
      expect(subject).to have_text("11")
      expect(subject).to have_text("2")
      expect(subject).to have_text("Jun-2024")
      expect(subject).to have_text("Jul-2024")
      expect(subject).to have_text("Aug-2024")
      expect(subject).to have_text("Sep-2024")
      expect(subject).to have_text("Oct-2024")
      expect(subject).to have_text("Nov-2024")
    end
  end

  describe "when diagnosis is not passed" do
    it 'defaults to "Hypertension" as diagnosis' do
      component = render_inline(described_class.new(
        monthly_follow_ups: monthly_follow_ups,
        period_info: period_info,
        region: region
      ))
      expect(component).to have_selector("p", text: I18n.t("progress_tab.diagnosis_report.monthly_follow_up_patients.subtitle", facility_name: region.name, diagnosis: "Hypertension"))
    end
  end

  describe "handling empty data" do
    let(:empty_data) { {} }

    it "renders nothing if monthly_follow_ups is empty" do
      component_with_empty_data = render_inline(described_class.new(
        monthly_follow_ups: empty_data,
        period_info: period_info,
        region: region,
        diagnosis: diagnosis
      ))
      expect(component_with_empty_data).to have_no_text("monthly_follow_ups")
    end

    it "renders nothing if period_info is empty" do
      component_with_empty_period_info = render_inline(described_class.new(
        monthly_follow_ups: monthly_follow_ups,
        period_info: empty_data,
        region: region,
        diagnosis: diagnosis
      ))
      expect(component_with_empty_period_info).to have_no_text("period_info")
    end
  end
end
