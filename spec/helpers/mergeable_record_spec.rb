require 'rails_helper'

describe MergeableRecord do
  it 'returns record with errors if invalid, and does not merge' do
    invalid_patient = FactoryBot.build(:patient, created_at: nil)
    patient         = MergeableRecord.new(invalid_patient).merge
    expect(patient.record).to be_invalid
    expect(Patient.count).to eq 0
    expect(Patient).to_not receive(:create)
  end

  it 'creates a new record if there is no existing record' do
    new_patient = FactoryBot.build(:patient, address: FactoryBot.create(:address))
    MergeableRecord.new(new_patient).merge
    expect(Patient.first.attributes.except('updated_on_server_at').with_int_timestamps)
      .to eq(new_patient.attributes.except('updated_on_server_at').with_int_timestamps)
  end

  it 'updates the existing record, if it exists' do
    existing_patient           = FactoryBot.create(:patient, address: FactoryBot.create(:address))
    updated_patient            = Patient.find(existing_patient.id)
    updated_patient.updated_at = 10.minutes.from_now
    patient                    = MergeableRecord.new(updated_patient).merge
    expect(patient.record).to_not have_changes_to_save
    expect(Patient.find(existing_patient.id).attributes.with_int_timestamps)
      .to eq(updated_patient.attributes.with_int_timestamps)
    expect(Patient.count).to eq 1
  end

  it 'returns the existing record if input record is older' do
    existing_patient           = FactoryBot.create(:patient, address: FactoryBot.create(:address))
    updated_patient            = Patient.find(existing_patient.id)
    updated_patient.updated_at = 10.minutes.ago
    MergeableRecord.new(updated_patient).merge
    expect(Patient.find(existing_patient.id).updated_at.to_i).to_not eq updated_patient.updated_at.to_i
    expect(Patient.count).to eq 1
  end

  it 'works for all models' do
    new_address = FactoryBot.build(:address)
    MergeableRecord.new(new_address).merge
    expect(Address.first.attributes.except('updated_on_server_at').with_int_timestamps)
      .to eq(new_address.attributes.except('updated_on_server_at').with_int_timestamps)

    new_phone_number = FactoryBot.build(:phone_number)
    MergeableRecord.new(new_phone_number).merge
    expect(PhoneNumber.first.attributes.except('updated_on_server_at').with_int_timestamps)
      .to eq(new_phone_number.attributes.except('updated_on_server_at').with_int_timestamps)
  end
end