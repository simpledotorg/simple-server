require 'rails_helper'

RSpec.describe UserAnalyticsQuery do
  let!(:users)    { create_list(:user, 2) }
  let!(:facility) { create(:facility) }

  let!(:months_ago)    { 5 }
  let!(:days_ago)      { 10 }
  let!(:current_month) { Date.current.beginning_of_month }
  let!(:current_day)   { Date.current }

  let!(:analytics) { UserAnalyticsQuery.new(facility,
                                            days_ago: days_ago,
                                            months_ago: months_ago) }

  let(:five_months_back)  { current_month - 5.months }
  let(:four_months_back)  { current_month - 4.months }
  let(:three_months_back) { current_month - 3.months }
  let(:two_months_back)   { current_month - 2.months }
  let(:one_month_back)    { current_month - 1.months }

  let(:ten_days_back)   { current_day - 10.days }
  let(:nine_days_back)  { current_day - 9.days }
  let(:eight_days_back) { current_day - 8.days }
  let(:seven_days_back) { current_day - 7.days }
  let(:six_days_back)   { current_day - 6.days }
  let(:five_days_back)  { current_day - 5.days }
  let(:four_days_back)  { current_day - 4.days }
  let(:three_days_back) { current_day - 3.days }
  let(:two_days_back)   { current_day - 2.days }
  let(:one_day_back)    { current_day - 1.days }

  before do
    #
    # MONTHLY DATA
    #
    [five_months_back, four_months_back].each do |month|
      #
      # register patients
      #
      registered_patients = travel_to(month) do
        patients = []

        users.each do |u|
          patients << create(:patient, gender: 'female', registration_facility: facility, registration_user: u)
          patients << create(:patient, gender: 'male', registration_facility: facility, registration_user: u)
          patients << create(:patient, gender: 'transgender', registration_facility: facility, registration_user: u)
        end

        patients.flatten
      end

      #
      # add blood_pressures next month
      #
      travel_to(month + 1.month) do
        users.each do |u|
          registered_patients.each do |patient|
            create(:blood_pressure,
                   :critical,
                   patient: patient,
                   facility: facility,
                   user: u)
          end
        end
      end

      #
      # add blood_pressures after a couple of months
      #
      travel_to(month + 2.months) do
        users.each do |u|
          registered_patients.each do |patient|
            create(:blood_pressure,
                   :under_control,
                   patient: patient,
                   facility: facility,
                   user: u)
          end
        end
      end
    end

    #
    # DAILY DATA
    #
    [five_days_back, four_days_back].each do |day|
      registered_patients = travel_to(day) do
        patients = []

        users.each do |u|
          patients << create(:patient, gender: 'female', registration_facility: facility, registration_user: u)
          patients << create(:patient, gender: 'male', registration_facility: facility, registration_user: u)
          patients << create(:patient, gender: 'transgender', registration_facility: facility, registration_user: u)
        end

        patients.flatten
      end

      #
      # add blood_pressures next day
      #
      travel_to(day + 1.day) do
        users.each do |u|
          registered_patients.each do |patient|
            create(:blood_pressure,
                   :critical,
                   patient: patient,
                   facility: facility,
                   user: u)
          end
        end
      end

      #
      # add blood_pressures after a couple of days
      #
      travel_to(day + 2.days) do
        users.each do |u|
          registered_patients.each do |patient|
            create(:blood_pressure,
                   :under_control,
                   patient: patient,
                   facility: facility,
                   user: u)
          end
        end
      end
    end

    LatestBloodPressuresPerPatientPerDay.refresh
  end

  context 'daily_follow_ups (for the specified facility)' do
    it 'returns daily follow-ups across Hypertension-only patients' do
      expected_output = { four_days_back => 6,
                          three_days_back => 12,
                          two_days_back => 6 }

      expect(analytics.daily_follow_ups).to eq(expected_output)
    end
  end

  context 'daily_registrations (for the specified facility)' do
    it 'returns daily registrations across Hypertension and Diabetes patients' do
      expected_output = { current_day => 0,
                          one_day_back => 0,
                          two_days_back => 0,
                          three_days_back => 0,
                          four_days_back => 6,
                          five_days_back => 6,
                          six_days_back => 0,
                          seven_days_back => 0,
                          eight_days_back => 0,
                          nine_days_back => 0 }

      expect(analytics.daily_registrations).to eq(expected_output)
    end
  end

  context 'monthly_follow_ups (for the specified facility)' do
    it 'returns month-on-month follow-ups for Hypertension-only patients grouped by gender' do
      expected_output = { ["female", one_month_back] => 8,
                          ["male", one_month_back] => 8,
                          ["transgender", one_month_back] => 8,

                          ["female", two_months_back] => 2,
                          ["male", two_months_back] => 2,
                          ["transgender", two_months_back] => 2,

                          ["female", three_months_back] => 4,
                          ["male", three_months_back] => 4,
                          ["transgender", three_months_back] => 4,

                          ["female", four_months_back] => 2,
                          ["male", four_months_back] => 2,
                          ["transgender", four_months_back] => 2 }

      expect(analytics.monthly_follow_ups).to eq(expected_output)
    end
  end

  context 'monthly_registrations (for the specified facility)' do
    it 'returns month-on-month registrations for both Hypertension and Diabetes patients grouped by gender' do
      expected_output = { ["female", current_month] => 0,
                          ["male", current_month] => 0,
                          ["transgender", current_month] => 0,

                          ["female", one_month_back] => 4,
                          ["male", one_month_back] => 4,
                          ["transgender", one_month_back] => 4,

                          ["female", two_months_back] => 0,
                          ["male", two_months_back] => 0,
                          ["transgender", two_months_back] => 0,

                          ["female", three_months_back] => 0,
                          ["male", three_months_back] => 0,
                          ["transgender", three_months_back] => 0,

                          ["female", four_months_back] => 2,
                          ["male", four_months_back] => 2,
                          ["transgender", four_months_back] => 2 }

      expect(analytics.monthly_registrations).to eq(expected_output)
    end
  end

  context 'monthly_htn_control (for the specified facility)' do
    it 'returns month-on-month Hypertension control numbers' do
      expected_output = {
        controlled_visits: {
          one_month_back => 12,
          two_months_back => 6,
          three_months_back => 6
        },
        total_visits: {
          one_month_back => 24,
          two_months_back => 6,
          three_months_back => 12,
          four_months_back => 6
        },
      }

      expect(analytics.monthly_htn_control).to eq(expected_output)
    end
  end

  context 'all_time_registrations (for the specified facility)' do
    it 'returns total registrations across Hypertension and Diabetes patients' do
      expected_output = { "female" => 8,
                          "male" => 8,
                          "transgender" => 8 }

      expect(analytics.all_time_registrations).to eq(expected_output)
    end
  end

  context 'all_time_follow_ups (for the specified facility)' do
    it 'returns total follow_ups across Hypertension-only patients' do
      expected_output = { "female" => 8,
                          "male" => 8,
                          "transgender" => 8 }

      expect(analytics.all_time_registrations).to eq(expected_output)
    end
  end
end
