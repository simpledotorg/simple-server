require 'rails_helper'

describe MergeRecord do
  it 'returns record with errors if invalid, and does not merge' do
    invalid_patient = FactoryBot.build(:patient, created_at: nil)
    patient         = MergeRecord.merge_by_id(invalid_patient)
    expect(patient).to be_invalid
    expect(Patient.count).to eq 0
    expect(Patient).to_not receive(:create)
  end

  it 'creates a new record if there is no existing record' do
    new_patient = FactoryBot.build(:patient, address: FactoryBot.create(:address))
    MergeRecord.merge_by_id(new_patient)
    expect(Utils.with_int_timestamps(Patient.first.attributes.except('updated_on_server_at')))
      .to eq Utils.with_int_timestamps(new_patient.attributes.except('updated_on_server_at'))
  end

  it 'updates the existing record, if it exists' do
    existing_patient           = FactoryBot.create(:patient, address: FactoryBot.create(:address))
    updated_patient            = Patient.find(existing_patient.id)
    updated_patient.updated_at = 10.minutes.from_now
    patient                    = MergeRecord.merge_by_id(updated_patient)
    expect(patient).to_not have_changes_to_save
    expect(Utils.with_int_timestamps(Patient.find(existing_patient.id).attributes))
      .to eq Utils.with_int_timestamps(updated_patient.attributes)
    expect(Patient.count).to eq 1
  end

  it 'returns the existing record if input record is older' do
    existing_patient           = FactoryBot.create(:patient, address: FactoryBot.create(:address))
    updated_patient            = Patient.find(existing_patient.id)
    updated_patient.updated_at = 10.minutes.ago
    MergeRecord.merge_by_id(updated_patient)
    expect(Patient.find(existing_patient.id).updated_at.to_i).to_not eq updated_patient.updated_at.to_i
    expect(Patient.count).to eq 1
  end

  it 'works for all models' do
    new_address = FactoryBot.build(:address)
    MergeRecord.merge_by_id(new_address)
    expect(Utils.with_int_timestamps(Address.first.attributes.except('updated_on_server_at')))
      .to eq Utils.with_int_timestamps(new_address.attributes.except('updated_on_server_at'))

    new_phone_number = FactoryBot.build(:phone_number)
    MergeRecord.merge_by_id(new_phone_number)
    expect(Utils.with_int_timestamps(PhoneNumber.first.attributes.except('updated_on_server_at')))
      .to eq Utils.with_int_timestamps(new_phone_number.attributes.except('updated_on_server_at'))
  end
end