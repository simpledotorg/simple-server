require 'rails_helper'

RSpec.describe ProgressTab::Diabetes::DiagnosisReportComponent, type: :component do
  let(:diabetes_reports_data) do
    {
      assigned_patients: 100,
      region: double('Region', name: 'Region 1'),
      diagnosis: 'diabetes'
    }
  end
  subject { render_inline(described_class.new(diabetes_reports_data: diabetes_reports_data)) }

  it 'renders the diabetes report section' do
    expect(subject).to have_css('div#diabetes-report')
  end

  it 'renders the back link with correct text and onclick behavior' do
    expect(subject).to have_css('a[onclick="goToPage(id=\'diabetes-report\', \'home-page\'); return false;"]', text: 'back')
  end

  it 'renders the Reports::ProgressAssignedPatientsComponent with correct data' do
    expect(subject.text).to include('Region 1')
    expect(subject.text).to include("#{diabetes_reports_data[:assigned_patients]}")
    expect(subject.text).to include('diabetes')
  end
end
