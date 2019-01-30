require 'rails_helper'

RSpec.describe ReturningPatientsQuery, type: :query do
  let(:facility_1) { create :facility }
  let(:facility_2) { create :facility }

  let!(:registered_patients_facility_1) { create_list :patient, 10, registration_facility: facility_1 }
  let!(:registered_patients_facility_2) { create_list :patient, 10, registration_facility: facility_2 }

  let!(:returning_patients_facility_1) { registered_patients_facility_1.take(5) }
  let!(:returning_patients_facility_2) { registered_patients_facility_2.take(5) }

  before :each do
    (returning_patients_facility_1 + returning_patients_facility_2).each do |patient|
      create :blood_pressure, patient: patient, facility: patient.registration_facility
    end
  end

  describe 'call' do
    it 'returns the number of returning patients for a single facility' do
      count = ReturningPatientsQuery.new(facility_1).call

      expect(count).to eq(facility_1.id => 5)
    end

    it 'returns the number of newly registered patients for a list of facilities' do
      count = ReturningPatientsQuery.new(Facility.all).call

      expect(count).to eq(facility_1.id => 5, facility_2.id => 5)
    end
  end
end