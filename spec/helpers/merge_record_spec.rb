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
    patient     = MergeRecord.merge_by_id(new_patient)
    expect(Patient.first.attributes.except('updated_on_server_at')).to eq patient.attributes.except('updated_on_server_at')
  end

  it 'updates the existing record, if it exists' do
    existing_patient           = FactoryBot.create(:patient, address: FactoryBot.create(:address))
    updated_patient            = Patient.find(existing_patient.id)
    updated_patient.updated_at = 10.minutes.from_now
    patient                    = MergeRecord.merge_by_id(updated_patient)
    expect(patient).to_not have_changes_to_save
    expect(Patient.find(existing_patient.id).attributes).to eq updated_patient.attributes
    expect(Patient.count).to eq 1
  end

  it 'returns the existing record if input record is older' do
    existing_patient           = FactoryBot.create(:patient, address: FactoryBot.create(:address))
    updated_patient            = Patient.find(existing_patient.id)
    updated_patient.updated_at = 10.minutes.ago
    MergeRecord.merge_by_id(updated_patient)
    expect(Patient.find(existing_patient.id).updated_at).to_not eq updated_patient.updated_at
    expect(Patient.count).to eq 1
  end

  it 'works for all models' do
    new_patient = FactoryBot.build(:patient, address: FactoryBot.create(:address))
    patient     = MergeRecord.merge_by_id(new_patient)
    expect(Patient.first.attributes.except('updated_on_server_at')).to eq patient.attributes.except('updated_on_server_at')

    address = MergeRecord.merge_by_id(FactoryBot.build(:address))
    expect(Address.first.attributes.except('updated_on_server_at')).to eq address.attributes.except('updated_on_server_at')

    phone_number = MergeRecord.merge_by_id(FactoryBot.build(:phone_number))
    expect(PhoneNumber.first.attributes.except('updated_on_server_at')).to eq phone_number.attributes.except('updated_on_server_at')
  end
end