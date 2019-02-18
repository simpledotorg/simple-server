require 'rails_helper'

describe Patient, type: :model do
  describe 'Associations' do
    it { should belong_to(:address) }
    it { should have_many(:phone_numbers) }
    it { should have_many(:blood_pressures) }
    it { should have_many(:prescription_drugs) }
    it { should have_many(:facilities).through(:blood_pressures) }
    it { should have_many(:appointments) }
    it { should have_one(:medical_history) }

    it 'has distinct facilities' do
      patient = FactoryBot.create(:patient)
      facility = FactoryBot.create(:facility)
      FactoryBot.create_list(:blood_pressure, 5, patient: patient, facility: facility)
      expect(patient.facilities.count).to eq(1)
    end

    it { should belong_to(:registration_facility).class_name("Facility") }
    it { should belong_to(:registration_user).class_name("User") }
  end

  describe 'Validations' do
    it_behaves_like 'a record that validates device timestamps'

    it 'validates that date of birth is not in the future' do
      patient = FactoryBot.build(:patient)
      patient.date_of_birth = 3.days.from_now
      expect(patient).to be_invalid
    end
  end

  describe 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end

  describe '.not_contacted' do
    let(:patient_to_followup) { create(:patient) }
    let(:patient_contacted) { create(:patient, contacted_by_counsellor: true) }
    let(:patient_could_not_be_contacted) { create(:patient, could_not_contact_reason: 'dead') }

    it 'includes uncontacted patients' do
      expect(Patient.not_contacted).to include(patient_to_followup)
    end

    it 'excludes already contacted patients' do
      expect(Patient.not_contacted).not_to include(patient_contacted)
    end

    it 'excludes patients who could not be contacted' do
      expect(Patient.not_contacted).not_to include(patient_could_not_be_contacted)
    end
  end

  describe 'Associations' do
    it { should have_many(:blood_pressures) }
    it { should have_many(:latest_blood_pressures) }

    it 'should sort blood pressures by the latest one first' do
      patient = FactoryBot.create(:patient)
      facility = FactoryBot.create(:facility)
      blood_pressures = FactoryBot.create_list(:blood_pressure, 5, patient: patient, facility: facility)

      expected_blood_pressures = blood_pressures.sort_by(&:device_created_at).reverse

      expect(patient.latest_blood_pressures).to eq(expected_blood_pressures)
    end
  end
end
