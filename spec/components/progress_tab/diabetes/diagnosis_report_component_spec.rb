require "rails_helper"

RSpec.describe ProgressTab::Diabetes::DiagnosisReportComponent, type: :component do
  let(:region) { double("Region", slug: "region_slug", name: "Region 1") }
  let(:period_june) { double("Period", type: "month", value: "2024-06-01") }
  let(:period_july) { double("Period", type: "month", value: "2024-07-01") }
  let(:period_august) { double("Period", type: "month", value: "2024-08-01") }
  let(:repository) { double("Repository") }
  let(:diabetes_reports_data) do
    {
      total_registrations: {
        period_june => 42,
        period_july => 44,
        period_august => 49
      },
      period_info: {
        period_june => {name: "Jun-2024", ltfu_since_date: "30-Jun-2023", ltfu_end_date: "30-Jun-2024"},
        period_july => {name: "Jul-2024", ltfu_since_date: "31-Jul-2023", ltfu_end_date: "31-Jul-2024"},
        period_august => {name: "Aug-2024", ltfu_since_date: "31-Aug-2023", ltfu_end_date: "31-Aug-2024"}
      },
      monthly_follow_ups: {
        period_june => 15,
        period_july => 20,
        period_august => 18
      },
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
    allow(repository).to receive(:monthly_follow_ups).and_return(diabetes_reports_data[:monthly_follow_ups])
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
    formatted_date = Time.zone.now.strftime("%d-%b-%Y at %I:%M %p")
    expect(subject).to have_text("Data last updated on #{formatted_date}")
  end

  it "renders the Reports::ProgressTotalRegistrationsComponent" do
    expect(subject).to have_text(region.name)
    expect(subject).to have_text("49")
  end
end
