require 'rails_helper'

RSpec.describe NewlyEnrolledPatientsQuery do
  let(:from_time) { 1.month.ago }
  let(:to_time) { Date.today }

  let(:facilities) { create_list :facility, 2 }

  describe '#call' do
    it 'returns the number of unique patients registerted at a list of facilities' do
      old_patients = facilities.flat_map do |facility|
        create_list_in_period(
          :patient, 3,
          from_time: 1.year.ago, to_time: from_time - 1.day,
          registration_facility: facility)
      end

      newly_enrolled_patients = facilities.flat_map do |facility|
        create_list_in_period(
          :patient, 3,
          from_time: from_time, to_time: to_time,
          registration_facility: facility)
      end

      results = NewlyEnrolledPatientsQuery.new(facilities: facilities, from_time: from_time, to_time: to_time).call

      expect(results).to match_array(newly_enrolled_patients)
      expect(results).not_to include(old_patients)
    end
  end
end