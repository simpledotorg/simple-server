require 'rails_helper'

RSpec.describe Facility, type: :model do
  describe 'Associations' do
    it { should have_many(:users) }
    it { should have_many(:blood_pressures).through(:encounters).source(:blood_pressures) }
    it { should have_many(:blood_sugars).through(:encounters).source(:blood_sugars)}
    it { should have_many(:prescription_drugs) }
    it { should have_many(:patients).through(:encounters) }
    it { should have_many(:appointments) }

    it { should have_many(:registered_patients).class_name("Patient").with_foreign_key("registration_facility_id") }

    it 'has distinct patients' do
      facility = create(:facility)
      patient = create(:patient)
      blood_pressures = create_list(:blood_pressure, 2, facility: facility, patient: patient)
      blood_sugars = create_list(:blood_sugar, 2, facility: facility, patient: patient)
      (blood_pressures + blood_sugars).each {|record| create(:encounter, :with_observables, patient: patient, observable: record, facility: facility)}
      expect(facility.patients.count).to eq(1)
    end

    it { should belong_to(:facility_group).optional }
  end

  describe 'Validations' do
    it { should validate_presence_of(:name)}
    it { should validate_presence_of(:district)}
    it { should validate_presence_of(:state)}
    it { should validate_presence_of(:country)}
    it { should validate_numericality_of(:pin)}
  end

  describe 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end
end
