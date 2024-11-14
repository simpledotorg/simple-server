require "rails_helper"

RSpec.describe ProgressTab::Diabetes::DiagnosisReportComponent, type: :component do
  include ApplicationHelper
  let(:diabetes_reports_data) do
    {
      assigned_patients: 100,
      region: double("Region", name: "Region 1"),
      diagnosis: "diabetes"
    }
  end
  let(:last_updated_at) {Time.current}

  subject { render_inline(described_class.new(diabetes_reports_data: diabetes_reports_data, last_updated_at: last_updated_at)) }

  it "renders the diabetes report section" do
    expect(subject).to have_css("div#diabetes-report")
  end

  it "renders the back link with correct text and onclick behavior" do
    expect(subject).to have_css('a[onclick="goToPage(id=\'diabetes-report\', \'home-page\'); return false;"]', text: "back")
  end

  it "renders the Reports::ProgressAssignedPatientsComponent with correct data" do
    expect(subject.text).to include("Region 1")
    expect(subject.text).to include(diabetes_reports_data[:assigned_patients].to_s)
    expect(subject.text).to include("diabetes")
  end

  it "displays the last updated date and time" do
    formatted_date = display_date(last_updated_at)
    formatted_time = display_time(last_updated_at)
    expect(subject).to have_text(I18n.t("progress_tab.last_updated_at", date: formatted_date, time: formatted_time))
  end
end
