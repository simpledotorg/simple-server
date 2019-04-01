require 'rails_helper'

RSpec.describe Analytics::UserAnalytics do
  let(:facility) { create :facility }
  let(:user) { create :user }
  let(:from_time) { Time.new(2019, 1, 1) }
  let(:to_time) { from_time + 12.weeks }

  let(:user_analytics) { Analytics::UserAnalytics.new(user, facility, from_time: from_time, to_time: to_time) }

  describe '#newly_enrolled_patients' do
    it 'returns the number of patients registered by the user' do
      create_list(:patient, 10, registration_user: user, registration_facility: facility)

      expect(user_analytics.registered_patients_count).to eq(10)
    end
  end

  describe '#blood_pressures_recorded_per_week' do
    before :each do
      12.times do |n|
        Timecop.travel(from_time + n.weeks) do
          create_list(:blood_pressure, 2, user: user, facility: facility)
        end
      end
    end
    it 'returns the number of blood pressures recorded by a user per week' do
      expected_counts = {
        Date.new(2018, 12, 30) => 2,
        Date.new(2019, 1, 06) => 2,
        Date.new(2019, 1, 13) => 2,
        Date.new(2019, 1, 20) => 2,
        Date.new(2019, 1, 27) => 2,
        Date.new(2019, 2, 03) => 2,
        Date.new(2019, 2, 10) => 2,
        Date.new(2019, 2, 17) => 2,
        Date.new(2019, 2, 24) => 2,
        Date.new(2019, 3, 03) => 2,
        Date.new(2019, 3, 10) => 2,
        Date.new(2019, 3, 17) => 2,
        Date.new(2019, 3, 24) => 0,
      }
      expect(user_analytics.blood_pressures_recorded_per_week).to eq(expected_counts)
    end
  end
end