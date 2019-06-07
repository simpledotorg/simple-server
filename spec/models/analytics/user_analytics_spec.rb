require 'rails_helper'

RSpec.describe Analytics::UserAnalytics do
  let(:facility) { create :facility }
  let(:user) { create :user }
  let(:from_time) { Time.new(2019, 1, 1) }
  let(:to_time) { from_time + 12.weeks }

  let(:user_analytics) { Analytics::UserAnalytics.new(user, facility, from_time: from_time, to_time: to_time) }

  describe '#registered_patients_count' do
    it 'returns the number of patients registered by the user during the period' do
      Timecop.travel(from_time) do
        create_list(:patient, 2, registration_user: user, registration_facility: facility)
      end

      expect(user_analytics.registered_patients_count).to eq(2)
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

  describe 'calls_made_by_user_at_facility' do
    before :each do
      Timecop.travel(from_time) do
        appointments = create_list(:appointment, 2, facility: facility)
        appointments.each do |appointment|
          create_list(:communication, 2, user: user, appointment: appointment)
        end
      end
    end
    it 'returns the number of calls made by the user at a facility during the time period' do
      expect(user_analytics.calls_made_by_user_at_facility).to eq(4)
    end
  end

  describe 'returning_patients_count_at_facility' do
    before :each do
      Timecop.travel(from_time) do
        patients = create_list(:patient, 2)
        patients.each do |patient|
          create_list(:blood_pressure, 2, patient: patient, user: user, facility: facility)
        end
      end
    end
    it 'returns the number of calls made by the user at a facility during the time period' do
      expect(user_analytics.returning_patients_count_at_facility).to eq(2)
    end
  end
end