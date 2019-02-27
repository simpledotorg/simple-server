require 'rails_helper'

RSpec.describe Analytics::UserAnalytics do
  let(:facility) { create :facility }
  let(:user) { create :user }
  let(:user_analytics) { Analytics::UserAnalytics.new(user, facility) }

  describe '#newly_enrolled_patients' do
    it 'returns the number of patients registered by the user' do
      create_list_in_period(
        :patient, 10,
        from_time: 9.months.ago, to_time: Date.today,
        registration_user: user, registration_facility: facility)

      expect(user_analytics.registered_patients_count).to eq(10)
    end
  end

  describe '#blood_pressures_recorded_per_week' do
    it 'returns the number of blood pressures recorded by a user per week' do
      expected_counts = {}
      12.times do |n|
        from_date = n.weeks.ago.at_beginning_of_week - 1.day
        to_date = from_date.at_end_of_week - 1.day
        count = rand(10)
        expected_counts[from_date.to_date] = count
        create_list_in_period(
          :blood_pressure, count,
          from_time: from_date, to_time: to_date,
          user: user, facility: facility)
      end

      expect(user_analytics.blood_pressures_recorded_per_week).to eq(expected_counts)
    end
  end
end