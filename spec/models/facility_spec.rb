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

  describe '.bp_counts_in_period' do
    let(:facility) { create(:facility) }
    let(:period_start) { 3.months.ago }
    let(:period_finish) { Time.current }
    let(:blood_pressure_in_period) { create(:blood_pressure, facility: facility, recorded_at: period_start + 1.day) }
    let(:blood_pressure_at_period_start) { create(:blood_pressure, facility: facility, recorded_at: period_start) }
    let(:blood_pressure_outside_period) do
      create(:blood_pressure, facility: facility, recorded_at: period_start - 1.day)
    end
    let!(:encounters) do
      [blood_pressure_in_period, blood_pressure_at_period_start, blood_pressure_outside_period].each do |record|
        create(:encounter, :with_observables, observable: record, facility: facility)
      end
    end
    let!(:results) { Facility.bp_counts_in_period(start: period_start, finish: period_finish) }

    it 'should count blood_pressures that were recorded in the period' do
      expect(results[facility.id]).to eq(2)
    end
  end
end
