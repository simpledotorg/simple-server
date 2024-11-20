require "rails_helper"

RSpec.describe Reports::ProgressTotalRegistrationsComponent, type: :component do
  let(:region) { double("Region", name: "Region 1") }
  let(:total_registrations_data) do
    {
      "2024-06-01" => 42,
      "2024-07-01" => 44,
      "2024-08-01" => 49,
      "2024-09-01" => 56,
      "2024-10-01" => 61,
      "2024-11-01" => 62
    }
  end

  let(:total_registrations) do
    total_registrations_data.map { |date, value| [Period.new(type: :month, value: date), value] }.to_h
  end

  let(:period_info) do
    total_registrations_data.keys.map do |date|
      period = Period.new(type: :month, value: date)
      ltfu_since_date = Date.parse(date).prev_year.end_of_month.strftime("%d-%b-%Y")
      [period, {name: Date.parse(date).strftime("%b-%Y"), ltfu_since_date: ltfu_since_date}]
    end.to_h
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
    expectations = [
      "42", "44", "49", "56", "61", "62",
      "Jun-2024", "Jul-2024", "Aug-2024", "Sep-2024", "Oct-2024", "Nov-2024"
    ]
    expectations.each { |expectation| expect(subject).to have_text(expectation) }
  end

  it "displays the correct number of total registrations" do
    total_registrations_data.values.each do |value|
      expect(subject).to have_text(value.to_s)
    end
  end
end
