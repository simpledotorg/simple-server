require "rails_helper"

RSpec.describe Reports::ProgressAssignedPatientsComponent, type: :component do
  let(:region) { double("Region", name: "Region 1") }
  let(:assigned_patients) { 100 }
  let(:diagnosis) { "hypertension" }

  subject { render_inline(described_class.new(assigned_patients: assigned_patients, region: region, diagnosis: diagnosis)) }

  it "renders the correct title for the assigned patients card" do
    expect(subject).to have_css("h2", text: I18n.t("progress_tab.diagnosis_report.assigned_patients_card.title"))
  end

  it "displays the assigned patients count" do
    expect(subject).to have_css("p", text: assigned_patients.to_s)
  end

  it "displays the correct subtitle with region and diagnosis" do
    expect(subject).to have_css("p", text: I18n.t("progress_tab.diagnosis_report.assigned_patients_card.subtitle", facility_name: region.name, diagnosis: diagnosis))
  end

  context "when diagnosis is not provided" do
    let(:diagnosis) { nil }

    subject { render_inline(described_class.new(assigned_patients: assigned_patients, region: region)) }

    it "uses the default diagnosis value (hypertension)" do
      expect(subject).to have_css("p", text: I18n.t("progress_tab.diagnosis_report.assigned_patients_card.subtitle", facility_name: region.name, diagnosis: "hypertension"))
    end
  end
end
