# frozen_string_literal: true

require "rails_helper"

RSpec.describe Teleconsultation, type: :model do
  it { should belong_to(:patient) }
  it { should belong_to(:medical_officer).class_name("User") }
  it { should belong_to(:requester).class_name("User").optional }
  it { should belong_to(:facility).optional }
  it { should have_many(:prescription_drugs) }

  context "Validations" do
    it_behaves_like "a record that validates device timestamps"
  end

  context "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  describe "#request" do
    let!(:nurse) { create(:user) }
    let!(:facility) { create(:facility) }
    let!(:teleconsultation) do
      FactoryBot.build(:teleconsultation,
        requester: nurse,
        facility: facility)
    end

    it "returns the teleconsult request data" do
      expect(teleconsultation.request).to include("requested_at",
        "requester_id" => nurse.id,
        "facility_id" => facility.id)
    end
  end

  describe "#record" do
    let!(:nurse) { create(:user) }
    let!(:medical_officer) { create(:user) }
    let!(:facility) { create(:facility) }
    let!(:teleconsultation) do
      FactoryBot.build(:teleconsultation,
        medical_officer: medical_officer,
        teleconsultation_type: "audio",
        patient_took_medicines: "yes",
        patient_consented: "yes",
        medical_officer_number: "",
        facility: facility)
    end

    it "returns the teleconsult record data" do
      expect(teleconsultation.record).to include("recorded_at",
        "teleconsultation_type" => "audio",
        "patient_took_medicines" => "yes",
        "patient_consented" => "yes",
        "medical_officer_number" => "")
    end
  end
end
