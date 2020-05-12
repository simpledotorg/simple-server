require 'rails_helper'
require 'tasks/scripts/clean_biswanath_dupes'

RSpec.describe CleanBiswanathDupes do
  let!(:dup_user) { create(:user, id: '2b469d02-f746-4550-bb91-6651143ca8cc') }
  let!(:real_user) { create(:user, full_name: 'biswanath-import-user') }

  describe 'identify_patient_matches' do
    it 'matches by name and age' do
      dup_patient = create(:patient, registration_user: dup_user, full_name: 'Test', age: 50)
      real_patient = create(:patient, registration_user: real_user, full_name: 'Test', age: 50)

      cleaner = CleanBiswanathDupes.new

      cleaner.identify_patient_matches

      expect(cleaner.exact_matches).to eq(dup_patient.id => real_patient.id)
      expect(cleaner.ambiguous_matches).to be_empty
      expect(cleaner.no_matches).to be_empty
    end

    it 'matches by name age and address' do
      dup_address = create(:address)
      real_address = create(:address, dup_address.attributes.except('id'))
      other_address = create(:address)

      dup_patient = create(:patient, registration_user: dup_user, full_name: 'Test', age: 50, address: dup_address)
      real_patient = create(:patient, registration_user: real_user, full_name: 'Test', age: 50, address: real_address)
      other_patient = create(:patient, registration_user: real_user, full_name: 'Test', age: 50, address: other_address)

      cleaner = CleanBiswanathDupes.new

      cleaner.identify_patient_matches

      expect(cleaner.exact_matches).to eq(dup_patient.id => real_patient.id)
      expect(cleaner.ambiguous_matches).to be_empty
      expect(cleaner.no_matches).to be_empty
    end

    it 'matches by name age address and phone' do
      dup_address = create(:address)
      real_address = create(:address, dup_address.attributes.except('id'))
      other_address = create(:address, dup_address.attributes.except('id'))

      dup_patient = create(:patient, registration_user: dup_user, full_name: 'Test', age: 50, address: dup_address)
      real_patient = create(:patient, registration_user: real_user, full_name: 'Test', age: 50, address: real_address)
      other_patient = create(:patient, registration_user: real_user, full_name: 'Test', age: 50, address: other_address)

      dup_phone = create(:patient_phone_number, number: '1234567890', patient: dup_patient)
      real_phone = create(:patient_phone_number, number: '1234567890', patient: real_patient)
      other_phone = create(:patient_phone_number, number: '0987654321', patient: other_patient)

      cleaner = CleanBiswanathDupes.new

      cleaner.identify_patient_matches

      expect(cleaner.exact_matches).to eq(dup_patient.id => real_patient.id)
      expect(cleaner.ambiguous_matches).to be_empty
      expect(cleaner.no_matches).to be_empty
    end

    it 'identifies patients with no matches' do
      dup_patient = create(:patient, registration_user: dup_user, full_name: 'Test', age: 50)

      cleaner = CleanBiswanathDupes.new

      cleaner.identify_patient_matches

      expect(cleaner.exact_matches).to be_empty
      expect(cleaner.ambiguous_matches).to be_empty
      expect(cleaner.no_matches).to contain_exactly(dup_patient)
    end

    it 'identifies patients with ambiguous matches' do
      dup_patient = create(:patient, registration_user: dup_user, full_name: 'Test', age: 50)
      real_patient = create(:patient, registration_user: real_user, full_name: 'Test', age: 50)
      other_patient = create(:patient, registration_user: real_user, full_name: 'Test', age: 50)

      cleaner = CleanBiswanathDupes.new

      cleaner.identify_patient_matches

      expect(cleaner.exact_matches).to be_empty
      expect(cleaner.ambiguous_matches).to contain_exactly(dup_patient)
      expect(cleaner.no_matches).to be_empty
    end
  end

  describe 'port_unmatched_patients' do
    it 'updates registration user of unmatched patients' do
      dup_patient_1 = create(:patient, registration_user: dup_user)
      dup_patient_2 = create(:patient, registration_user: dup_user)

      other_patient = create(:patient)
      other_user = other_patient.registration_user

      cleaner = CleanBiswanathDupes.new

      cleaner.no_matches = [dup_patient_1, dup_patient_2]

      cleaner.call

      expect(dup_patient_1.registration_user).to eq(real_user)
      expect(dup_patient_2.registration_user).to eq(real_user)

      expect(other_patient.registration_user).to eq(other_user)
    end
  end

  describe 'deactivate_ambiguous_patients' do
    it 'deactivates all ambiguous patients' do
      dup_patient_1 = create(:patient, registration_user: dup_user)
      dup_patient_2 = create(:patient, registration_user: dup_user)

      other_patient = create(:patient)
      other_user = other_patient.registration_user

      cleaner = CleanBiswanathDupes.new

      cleaner.ambiguous_matches = [dup_patient_1, dup_patient_2]

      expect(dup_patient_1).to receive(:discard_data)
      expect(dup_patient_2).to receive(:discard_data)

      cleaner.call
    end
  end
end
