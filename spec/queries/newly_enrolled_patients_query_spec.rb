require 'rails_helper'

RSpec.describe NewlyEnrolledPatientsQuery, type: :query do
  let(:facility_1) { create :facility }
  let(:facility_2) { create :facility }

  before :each do
    4.times do |n|
      create_list :patient, 10, registration_facility: facility_1, device_created_at: n.months.ago
      create_list :patient, 10, registration_facility: facility_2, device_created_at: n.months.ago
    end
  end

  describe 'call' do
    it 'returns the number of newly registered patients for a single facility' do
      count = NewlyEnrolledPatientsQuery.new(facility_1).call

      expect(count).to eq(facility_1.id => 10)
    end

    it 'returns the number of newly registered patients for a list of facilities' do
      count = NewlyEnrolledPatientsQuery.new(Facility.all).call

      expect(count).to eq(facility_1.id => 40, facility_2.id => 40)
    end

    it 'returns the number of newly registered patients for a list of facilities grouped by period' do
      count = NewlyEnrolledPatientsQuery.new(Facility.all).call(group_by_period: { period: :month, column: :device_created_at })

      4.times do |n|
        expect(count).to include([facility_1.id, n.months.ago.at_beginning_of_month.to_date] => 10)
        expect(count).to include([facility_2.id, n.months.ago.at_beginning_of_month.to_date] => 10)
      end
    end
  end
end