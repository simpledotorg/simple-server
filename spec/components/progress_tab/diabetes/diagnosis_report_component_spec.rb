require "rails_helper"

RSpec.describe ProgressTab::Diabetes::DiagnosisReportComponent, type: :component do
  let(:region) { double("Region", slug: "region_slug", name: "Region 1") }
  let(:repository) { double("Repository") }

  let(:current_date) { Date.new(2024, 9, 1) } # Replace with a fixed date for consistent test results
  let(:diabetes_reports_data) do
    periods = (1..3).map { |n| current_date - n.months }
    {
      total_registrations: periods.index_with { |date| 40 + date.month }, # Sample logic for registrations
      period_info: periods.index_with do |date|
        {
          name: date.strftime("%b-%Y"),
          ltfu_since_date: (date - 1.year).end_of_month.strftime("%d-%b-%Y"),
          ltfu_end_date: date.end_of_month.strftime("%d-%b-%Y")
        }
      end,
      region: region,
      assigned_patients: 100,
      diagnosis: "diabetes"
    }
  end

  let(:last_updated_at) { Time.current }

  before do
    allow(repository).to receive(:cumulative_diabetes_registrations).and_return(diabetes_reports_data[:total_registrations])
    allow(repository).to receive(:cumulative_assigned_diabetic_patients).and_return(diabetes_reports_data[:assigned_patients])
    allow(repository).to receive(:period_info).and_return(diabetes_reports_data[:period_info])
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
end
