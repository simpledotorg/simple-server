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
