require "rails_helper"

RSpec.describe Seed::PatientSeeder do
  it "creates patients and related objects" do
    user = create(:user)
    facility = user.facility

    expect {
      Seed::PatientSeeder.call(facility, user, config: Seed::Config.new, logger: logger)
    }.to change { Patient.count }.by(4)
      .and change { Address.count }.by(4)
      .and change { MedicalHistory.count }.by(4)
      .and change { PatientBusinessIdentifier.count }.by(4)
      .and change { PatientPhoneNumber.count }.by(4)
      .and change { Facility.count }.by(0)
      .and change { User.count }.by(0)
  end

  it "creates patients with hypertension" do
    user = create(:user)
    facility = user.facility

    _result, patient_results = Seed::PatientSeeder.call(facility, user, config: Seed::Config.new, logger: logger)
    patient_results.each do |(id, _recorded_at)|
      patient = Patient.find(id)
      expect(patient.registration_facility).to eq(facility)
      expect(patient.assigned_facility).to eq(facility)
    end
    expect(facility.assigned_patients.count).to eq(4)
    expect(facility.assigned_patients.with_hypertension.count).to eq(4)
    expect(facility.assigned_patients.with_hypertension.where(status: "active").count).to be >= 3
  end
end
