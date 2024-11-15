require "rails_helper"

RSpec.describe Reports::ProgressTotalRegistrationsComponent, type: :component do
  let(:region) { double("Region", name: "Region 1") }
  let(:total_registrations) do
    {
      Period.new(type: :month, value: "2024-06-01") => 42,
      Period.new(type: :month, value: "2024-07-01") => 44,
      Period.new(type: :month, value: "2024-08-01") => 49,
      Period.new(type: :month, value: "2024-09-01") => 56,
      Period.new(type: :month, value: "2024-10-01") => 61,
      Period.new(type: :month, value: "2024-11-01") => 62
    }
  end
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
  let(:diagnosis) { "diabetes" }

  subject do
    render_inline(described_class.new(
      total_registrations: total_registrations,
      period_info: period_info,
      region: region,
      diagnosis: diagnosis
    ))
  end

  it "renders the component wrapper div" do
    expect(subject).to have_css("div.mb-8px.p-16px.bgc-white.bs-card")
  end

  it "renders the title with correct translation" do
    expect(subject).to have_text(I18n.t("progress_tab.diagnosis_report.total_registered_patients.title"))
  end

  it "renders the subtitle with the region name and diagnosis" do
    expect(subject).to have_text(I18n.t("progress_tab.diagnosis_report.total_registered_patients.subtitle", facility_name: region.name, diagnosis: diagnosis))
  end

  it "renders the user analytics data bar graph partial" do
    expect(subject).to have_selector('div[data-graph-type="bar-chart"]')
  end

  it "passes the correct data to the data bar graph partial" do
    expect(subject).to have_selector('div[data-graph-type="bar-chart"]')
    expect(subject).to have_text("42")
    expect(subject).to have_text("44")
    expect(subject).to have_text("49")
    expect(subject).to have_text("56")
    expect(subject).to have_text("61")
    expect(subject).to have_text("62")
    expect(subject).to have_text("Jun-2024")
    expect(subject).to have_text("Jul-2024")
    expect(subject).to have_text("Aug-2024")
    expect(subject).to have_text("Sep-2024")
    expect(subject).to have_text("Oct-2024")
    expect(subject).to have_text("Nov-2024")
  end

  it "displays the correct number of total registrations" do
    total_values = total_registrations.values
    total_values.each do |value|
      expect(subject).to have_text(value.to_s)
    end
  end
end
