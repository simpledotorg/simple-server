require 'rails_helper'

RSpec.describe UniquePatientsEnrolledQuery do
  let(:from_time) { 1.year.ago }
  let(:to_time) { Date.today }

  let(:facilities) { create_list :facility, 2 }

  describe '#call' do
    it 'returns the number of unique patients registerted at a list of facilities' do
      patients = facilities.flat_map do |facility|
        create_list_in_period(:patient, 3, from_time: from_time, to_time: to_time, registration_facility: facility)
      end

      expect(UniquePatientsEnrolledQuery.new(facilities: facilities).call).to match_array(patients)
    end
  end
end