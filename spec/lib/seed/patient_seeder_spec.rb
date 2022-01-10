require "rails_helper"

RSpec.describe Seed::PatientSeeder do
  it "creates patients and related objects" do
    facility = create(:facility)
    _user = create(:user, registration_facility: facility)
    expect {
      Seed::PatientSeeder.call(facility, user_ids: facility.user_ids, config: Seed::Config.new, logger: logger)
    }.to change { Patient.count }.by(4)
      .and change { Address.count }.by(4)
      .and change { MedicalHistory.count }.by(4)
      .and change { PatientBusinessIdentifier.count }.by(4)
      .and change { PatientPhoneNumber.count }.by(4)
      .and change { Facility.count }.by(0)
      .and change { User.count }.by(0)
  end

  it "creates patients with hypertension" do
    facility = create(:facility)
    user = create(:user, registration_facility: facility)

    _result, patient_results = Seed::PatientSeeder.call(facility, user_ids: facility.user_ids, config: Seed::Config.new, logger: logger)
    patient_results.each do |(id, _recorded_at)|
      patient = Patient.find(id)
      expect(patient.registration_facility).to eq(facility)
      expect(patient.registration_user).to eq(user)
      expect(patient.assigned_facility).to eq(facility)
    end
    expect(facility.assigned_patients.count).to eq(4)
    expect(facility.assigned_patients.with_hypertension.count).to eq(4)
    # This is a loose expectation because we introduce randomness into our patient statuses
    expect(facility.assigned_patients.with_hypertension.where(status: "active").count).to be >= 2
  end

  it "creates patients with diabetes if facility has diabetes enabled" do
    facility = create(:facility, enable_diabetes_management: true)
    create(:user, registration_facility: facility)

    _result, _patient_results = Seed::PatientSeeder.call(facility, user_ids: facility.user_ids, config: Seed::Config.new, logger: logger)
    expect(facility.assigned_patients.with_diabetes.count).to be > 0
  end
end
