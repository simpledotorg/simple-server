require "rails_helper"

RSpec.describe ProgressTab::Hypertension::DiagnosisReportComponent, type: :component do
  let(:region) { double("Region", slug: "region_slug", name: "Region 1") }
  let(:repository) { double("Repository") }
  let(:last_updated_at) { Time.current }

  let(:data) do
    {
      "2024-06-01" => 42,
      "2024-07-01" => 44,
      "2024-08-01" => 49
    }
  end

  let(:total_registrations) do
    data.map { |date_str, value| [Period.new(type: :month, value: date_str), value] }.to_h
  end
  
  let(:period_info) do
    data.keys.map do |date_str|
      period = Period.new(type: :month, value: date_str)
      date = Date.parse(date_str)
      [
        period,
        {
          name: date.strftime("%b-%Y"),
          ltfu_since_date: (date - 1.year).end_of_month.strftime("%d-%b-%Y"),
          ltfu_end_date: date.end_of_month.strftime("%d-%b-%Y")
        }
      ]
    end.to_h
  end

  let(:monthly_follow_ups_data) do
    {
      "2024-06-01" => 20,
      "2024-07-01" => 25,
      "2024-08-01" => 30
    }
  end

  let(:monthly_follow_ups) do
    monthly_follow_ups_data.map { |date_str, value| [Period.new(type: :month, value: date_str), value] }.to_h
  end

  let(:missed_visits_data) do
    {
      "2024-06-01" => 10,
      "2024-07-01" => 12,
      "2024-08-01" => 15
    }
  end

  let(:missed_visits) do
    missed_visits_data.map { |date_str, value| [Period.new(type: :month, value: date_str), value] }.to_h
  end

  let(:missed_visits_rates_data) do
    {
      "2024-06-01" => 0.5,
      "2024-07-01" => 0.55,
      "2024-08-01" => 0.6
    }
  end

  let(:missed_visits_rates) do
    missed_visits_rates_data.map { |date_str, value| [Period.new(type: :month, value: date_str), value] }.to_h
  end

  let(:adjusted_patients_data) do
    {
      "2024-06-01" => 120,
      "2024-07-01" => 130,
      "2024-08-01" => 140
    }
  end

  let(:adjusted_patients) do
    adjusted_patients_data.map { |date_str, value| [Period.new(type: :month, value: date_str), value] }.to_h
  end

  let(:controlled) do
    {
      "2024-06-01" => 5,
      "2024-07-01" => 6,
      "2024-08-01" => 7
    }
  end

  let(:controlled_rates) do
    controlled.map { |date_str, value| [Period.new(type: :month, value: date_str), value] }.to_h
  end

  let(:uncontrolled_data) do
    {
      "2024-06-01" => 15,
      "2024-07-01" => 18,
      "2024-08-01" => 20
    }
  end

  let(:uncontrolled) do
    uncontrolled_data.map { |date_str, value| [Period.new(type: :month, value: date_str), value] }.to_h
  end

  let(:uncontrolled_rates_data) do
    {
      "2024-06-01" => 0.15,
      "2024-07-01" => 0.18,
      "2024-08-01" => 0.20
    }
  end

  let(:uncontrolled_rates) do
    uncontrolled_rates_data.map { |date_str, value| [Period.new(type: :month, value: date_str), value] }.to_h
  end

  let(:cohort_data) do
    [
      { "controlled" => 1, "no_bp" => 3, "missed_visits" => 1, "uncontrolled" => 2, "controlled_rate" => 14, "no_bp_rate" => 43, "missed_visits_rate" => 14, "uncontrolled_rate" => 29, "period" => Period.new(type: :quarter, value: "Q3-2024"), "registration_period" => "Q2-2024", "registered" => 7, "results_in" => "Q3-2024" },
      { "controlled" => 1, "no_bp" => 4, "missed_visits" => 7, "uncontrolled" => 3, "controlled_rate" => 7, "no_bp_rate" => 27, "missed_visits_rate" => 46, "uncontrolled_rate" => 20, "period" => Period.new(type: :quarter, value: "Q2-2024"), "registration_period" => "Q1-2024", "registered" => 15, "results_in" => "Q2-2024" },
      { "controlled" => 1, "no_bp" => 1, "missed_visits" => 1, "uncontrolled" => 1, "controlled_rate" => 25, "no_bp_rate" => 25, "missed_visits_rate" => 25, "uncontrolled_rate" => 25, "period" => Period.new(type: :quarter, value: "Q1-2024"), "registration_period" => "Q4-2023", "registered" => 4, "results_in" => "Q1-2024" },
      { "controlled" => 0, "no_bp" => 2, "missed_visits" => 6, "uncontrolled" => 1, "controlled_rate" => 0, "no_bp_rate" => 22, "missed_visits_rate" => 67, "uncontrolled_rate" => 11, "period" => Period.new(type: :quarter, value: "Q4-2023"), "registration_period" => "Q3-2023", "registered" => 9, "results_in" => "Q4-2023" }
    ]
  end

  let(:hypertension_reports_data) do
    {
      total_registrations: total_registrations,
      period_info: period_info,
      region: region,
      assigned_patients: 100,
      monthly_follow_ups: monthly_follow_ups,
      missed_visits: missed_visits,
      missed_visits_rates: missed_visits_rates,
      adjusted_patients: adjusted_patients,
      controlled: controlled,
      controlled_rates: controlled_rates,
      uncontrolled: uncontrolled,
      uncontrolled_rates: uncontrolled_rates,
      diagnosis: "hypertension"
    }
  end

  before do
    allow(repository).to receive(:cumulative_registrations).and_return(total_registrations)
    allow(repository).to receive(:cumulative_assigned_patients).and_return(hypertension_reports_data[:assigned_patients])
    allow(repository).to receive(:period_info).and_return(period_info)
    allow(repository).to receive(:monthly_follow_ups).and_return(monthly_follow_ups)
    allow(repository).to receive(:missed_visits).and_return(missed_visits)
    allow(repository).to receive(:missed_visits_rates).and_return(missed_visits_rates)
    allow(repository).to receive(:adjusted_patients).and_return(hypertension_reports_data[:adjusted_patients])
    allow(repository).to receive(:controlled).and_return(controlled)
    allow(repository).to receive(:controlled_rates).and_return(controlled_rates)
    allow(repository).to receive(:uncontrolled).and_return(uncontrolled)
    allow(repository).to receive(:uncontrolled_rates).and_return(uncontrolled_rates)
    allow(region).to receive(:slug).and_return("region_slug")
  end

  subject do
    render_inline(described_class.new(
      hypertension_reports_data: hypertension_reports_data,
      cohort_data: cohort_data,
      last_updated_at: last_updated_at
    ))
  end

  it "renders the hypertension report section" do
    expect(subject).to have_css("div#hypertension-report")
  end

  it "renders the back link with correct text and onclick behavior" do
    expect(subject).to have_css(
      'a[onclick="goToPage(\'hypertension-report\', \'home-page\'); return false;"]',
      text: I18n.t("back")
    )
  end

  it "renders the Reports::ProgressAssignedPatientsComponent with correct data" do
    expect(subject).to have_text(region.name)
    expect(subject.text).to include(hypertension_reports_data[:assigned_patients].to_s)
    expect(subject).to have_text("hypertension")
  end

  it "displays the last updated date and time" do
    formatted_date_time = last_updated_at.strftime("%-d-%b-%Y at %I:%M %p")
    expect(subject).to have_text("Data last updated on #{formatted_date_time}")
  end

  it "renders the Reports::ProgressTotalRegistrationsComponent" do
    expect(subject).to have_text(region.name)
    expect(subject).to have_text("49")
  end

  it "renders the Reports::ProgressMonthlyFollowUpsComponent" do
    monthly_follow_ups.values.each do |value|
      expect(subject).to have_text(value.to_s)
    end
  end

  it "renders the missed visits data correctly" do
    missed_visits.values.each do |value|
      expect(subject).to have_text(value.to_s)
    end
  end

  it "renders the controlled data correctly" do
    controlled.values.each do |value|
      expect(subject).to have_text(value.to_s)
    end
  end

  it "renders the uncontrolled data correctly" do
    uncontrolled.values.each do |value|
      expect(subject).to have_text(value.to_s)
    end
  end

  it "renders cohort data correctly" do
    cohort_data.each do |cohort|
      expect(subject).to have_text("#{cohort['registered']}")
      expect(subject).to have_text("#{cohort['controlled']}")
      expect(subject).to have_text("#{cohort['uncontrolled']}")
      expect(subject).to have_text("#{cohort['no_bp']}")
      expect(subject).to have_text("#{cohort['uncontrolled']}")
      
    end
  end

end
