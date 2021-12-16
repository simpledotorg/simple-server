require "rails_helper"

describe Mergeable do
  it "returns record with errors if invalid, and does not merge" do
    invalid_patient = FactoryBot.build(:patient, device_created_at: nil)
    patient = Patient.merge(invalid_patient.attributes)
    expect(patient).to be_invalid
    expect(Patient.count).to eq 0
    expect(Patient).to_not receive(:create)
  end

  it "does not update a discarded record" do
    discarded_patient = FactoryBot.create(:patient, deleted_at: Time.now)
    update_attributes = discarded_patient.attributes.merge(age: discarded_patient.current_age + 3,
      updated_at: 3.years.from_now)

    expect(Patient.merge(update_attributes).attributes.with_int_timestamps)
      .to eq(discarded_patient.attributes.with_int_timestamps)
  end

  it "creates a new record if there is no existing record" do
    new_patient = FactoryBot.build(:patient, address: FactoryBot.create(:address))
    Patient.merge(new_patient.attributes)
    expect(Patient.first.attributes.except("updated_at", "created_at").with_int_timestamps)
      .to eq(new_patient.attributes.except("updated_at", "created_at").with_int_timestamps)
  end

  it "updates the existing record, if it exists" do
    existing_patient = FactoryBot.create(:patient, address: FactoryBot.create(:address))
    updated_patient = Patient.find(existing_patient.id)
    updated_patient.updated_at = 10.minutes.from_now
    patient = Patient.merge(updated_patient.attributes)
    expect(patient).to_not have_changes_to_save
    expect(Patient.find(existing_patient.id).attributes.with_int_timestamps.except("updated_at"))
      .to eq(updated_patient.attributes.with_int_timestamps.except("updated_at"))
    expect(Patient.count).to eq 1
  end

  it "returns the existing record touched if input record is older" do
    existing_patient = FactoryBot.create(:patient, updated_at: 10.minutes.ago, address: FactoryBot.create(:address))
    updated_patient = Patient.find(existing_patient.id)
    now = Time.current

    updated_patient.updated_at = 20.minutes.ago
    updated_patient.device_updated_at = 20.minutes.ago

    Timecop.freeze(now) do
      Patient.merge(updated_patient.attributes)
    end

    expect(Patient.find(existing_patient.id).updated_at.to_i).to eq now.to_i
    expect(Patient.count).to eq 1
  end

  it "returns the existing record untouched if input record is equally up-to-date" do
    existing_patient = FactoryBot.create(:patient, address: FactoryBot.create(:address))
    updated_at = existing_patient.updated_at

    Patient.merge(existing_patient.attributes)

    expect(Patient.find(existing_patient.id).updated_at.to_i).to eq updated_at.to_i
    expect(Patient.count).to eq 1
  end

  it "counts metrics for old merges" do
    existing_patient = FactoryBot.create(:patient, address: FactoryBot.create(:address))
    updated_patient = Patient.find(existing_patient.id)

    updated_patient.device_updated_at = 10.minutes.ago

    expect(Statsd.instance).to receive(:increment).with("merge.Patient.old")
    Patient.merge(updated_patient.attributes)
  end

  it "counts metrics if the existing record device_updated_at is the same as the new one" do
    timestamp = Time.zone.parse("March 1st 04:00:00 IST")
    existing_patient = FactoryBot.create(:patient, address: FactoryBot.create(:address), device_updated_at: timestamp)
    updated_patient = Patient.find(existing_patient.id)

    updated_patient.device_updated_at = existing_patient.device_updated_at

    expect(Statsd.instance).to receive(:increment).with("merge.Patient.identical")
    Patient.merge(updated_patient.attributes)
  end

  it "works for all models" do
    new_address = FactoryBot.build(:address)
    Address.merge(new_address.attributes)
    expect(Address.first.attributes.except("updated_at", "created_at").with_int_timestamps)
      .to eq(new_address.attributes.except("updated_at", "created_at").with_int_timestamps)

    new_patient = FactoryBot.create(:patient, phone_numbers: [])
    new_phone_number = FactoryBot.build(:patient_phone_number, patient: new_patient)
    PatientPhoneNumber.merge(new_phone_number.attributes)
    expect(PatientPhoneNumber.first.attributes.except("updated_at", "created_at").with_int_timestamps)
      .to eq(new_phone_number.attributes.except("updated_at", "created_at").with_int_timestamps)

    facility = FactoryBot.create(:facility)
    new_blood_pressure = FactoryBot.build(:blood_pressure, facility: facility)
    BloodPressure.merge(new_blood_pressure.attributes)
    expect(BloodPressure.first.attributes.except("updated_at", "created_at").with_int_timestamps)
      .to eq(new_blood_pressure.attributes.except("updated_at", "created_at").with_int_timestamps)
  end
end
