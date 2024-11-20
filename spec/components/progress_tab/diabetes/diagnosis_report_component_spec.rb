require "rails_helper"

RSpec.describe ProgressTab::Diabetes::DiagnosisReportComponent, type: :component do
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

  let(:diabetes_reports_data) do
    {
      total_registrations: total_registrations,
      period_info: period_info,
      region: region,
      assigned_patients: 100,
      monthly_follow_ups: monthly_follow_ups,
      diagnosis: "diabetes"
    }
  end

  let(:last_updated_at) { Time.current }

  before do
    allow(repository).to receive(:cumulative_diabetes_registrations).and_return(total_registrations)
    allow(repository).to receive(:cumulative_assigned_diabetic_patients).and_return(diabetes_reports_data[:assigned_patients])
    allow(repository).to receive(:period_info).and_return(period_info)
    allow(repository).to receive(:monthly_follow_ups).and_return(monthly_follow_ups)
    allow(region).to receive(:slug).and_return("region_slug")
  end

  subject do
    render_inline(described_class.new(
      diabetes_reports_data: diabetes_reports_data,
      last_updated_at: last_updated_at
    ))
  end

  it "renders the diabetes report section" do
    expect(subject).to have_css("div#diabetes-report")
  end

  it "renders the back link with correct text and onclick behavior" do
    expect(subject).to have_css(
      'a[onclick="goToPage(id=\'diabetes-report\', \'home-page\'); return false;"]',
      text: "back"
    )
  end

  it "renders the Reports::ProgressAssignedPatientsComponent with correct data" do
    expect(subject).to have_text(region.name)
    expect(subject.text).to include(diabetes_reports_data[:assigned_patients].to_s)
    expect(subject).to have_text("diabetes")
  end

  it "displays the last updated date and time" do
    formatted_date_time = last_updated_at.strftime("%d-%b-%Y at %I:%M %p")
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
end
