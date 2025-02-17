# spec/components/progress_tab/diabetes/missed_visits_component_spec.rb
require "rails_helper"

RSpec.describe ProgressTab::Diabetes::MissedVisitsComponent, type: :component do
  let(:region) { double("Region", name: "Region 1") }
  let(:missed_visits_data) do
    {
      "2024-06-01" => 10,
      "2024-07-01" => 12,
      "2024-08-01" => 15
    }
  end
  let(:adjusted_patients_data) do
    {
      "2024-06-01" => 120,
      "2024-07-01" => 130,
      "2024-08-01" => 140
    }
  end
  let(:missed_visits_rates_data) do
    {
      "2024-06-01" => 0.5,
      "2024-07-01" => 0.55,
      "2024-08-01" => 0.6
    }
  end
  let(:period_info_data) do
    {
      "2024-06-01" => {name: "Jun-2024"},
      "2024-07-01" => {name: "Jul-2024"},
      "2024-08-01" => {name: "Aug-2024"}
    }
  end

  let(:missed_visits) do
    missed_visits_data.map { |date_str, value| [Period.new(type: :month, value: date_str), value] }.to_h
  end

  let(:adjusted_patients) do
    adjusted_patients_data.map { |date_str, value| [Period.new(type: :month, value: date_str), value] }.to_h
  end

  let(:missed_visits_rates) do
    missed_visits_rates_data.map { |date_str, value| [Period.new(type: :month, value: date_str), value] }.to_h
  end

  let(:period_info) do
    period_info_data.map { |date_str, value| [Period.new(type: :month, value: date_str), value] }.to_h
  end

  let(:missed_visits_report_data) do
    {
      missed_visits_rates: missed_visits_rates,
      missed_visits: missed_visits,
      adjusted_patients: adjusted_patients,
      period_info: period_info,
      region: region
    }
  end

  subject do
    render_inline(described_class.new(
      missed_visits_rates: missed_visits_rates,
      missed_visits: missed_visits,
      adjusted_patients: adjusted_patients,
      period_info: period_info,
      region: region
    ))
  end

  it "renders the missed visits section" do
    expect(subject).to have_css("div.mb-8px.p-16px.bgc-white.bs-card")
  end

  it "renders the title correctly" do
    expect(subject).to have_text("Diabetes")
  end

  it "renders the title correctly" do
    expect(subject).to have_text("Missed visits")
  end

  it "displays the region name" do
    expect(subject).to have_text(region.name)
  end

  it "renders the help circle and tooltip correctly" do
    expect(subject).to have_css("div[data-element-type='help-circle']")
    expect(subject).to have_css("div[data-element-type='tooltip']")
  end

  it "renders the bar graph with the correct data" do
    expect(subject).to have_css("div[data-element-type='bar']")
  end

  it "displays the missed visits data correctly" do
    missed_visits_data.each do |date, value|
      expect(subject).to have_text(value.to_s)
    end
  end

  it "displays the adjusted patients data correctly" do
    adjusted_patients_data.each do |date, value|
      expect(subject).to have_text(value.to_s)
    end
  end

  it "displays the missed visits rates correctly" do
    missed_visits_rates_data.each do |date, value|
      expect(subject).to have_text(value.to_s)
    end
  end
end
