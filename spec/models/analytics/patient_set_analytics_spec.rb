require 'rails_helper'

RSpec.describe Analytics::PatientSetAnalytics do
  let(:from_time) { Date.today.at_beginning_of_month }
  let(:to_time) { Date.today.at_end_of_month }

  let(:past_options) { { from_time: 1.year.ago, to_time: from_time.prev_day } }
  let(:current_options) { { from_time: from_time, to_time: to_time } }

  describe '#unique_patients_count' do
    it 'returns the number of unique patients in the list' do
      _patients = create_list_in_period :patient, 5, from_time: 1.year.ago, to_time: to_time

      analytics = Analytics::PatientSetAnalytics.new(Patient.all, from_time, to_time)
      expect(analytics.unique_patients_count).to eq(5)
    end
  end

  describe '#newly_enrolled_patients_count' do
    it 'returns the number of patients newly enrolled in the period' do
      _old_patients = create_list_in_period :patient, 5, past_options
      _new_patients = create_list_in_period :patient, 2, current_options

      analytics = Analytics::PatientSetAnalytics.new(Patient.all, from_time, to_time)
      expect(analytics.newly_enrolled_patients_count).to eq(2)
    end
  end

  xdescribe '#newly_enrolled_patients_count_per_month' do
    it 'returns the number of patients newly enrolled per month' do
      expected_counts = {}
      5.times do
        n = rand(4)
        start_of_month = (Date.today - n.months).at_beginning_of_month
        create_in_period :patient, from_time: start_of_month, to_time: start_of_month.at_end_of_month

        date_key = start_of_month.to_date
        if expected_counts[date_key].present?
          expected_counts[date_key] += 1
        else
          expected_counts[date_key] = 1
        end
      end

      analytics = Analytics::PatientSetAnalytics.new(Patient.all, from_time, to_time)
      expect(analytics.newly_enrolled_patients_count_per_month(4)).to include(expected_counts)
    end
  end

  describe '#returning_patients_count' do
    it 'returns the number of patients that where recorded before from_time and have BP recording in the give period' do
      _old_patients = create_list_in_period :patient, 5, past_options
      _new_patients = create_list_in_period :patient, 2, current_options

      Patient.all.each do |patient|
        create_in_period :blood_pressure, current_options.merge(patient: patient)
      end

      analytics = Analytics::PatientSetAnalytics.new(Patient.all, from_time, to_time)
      expect(analytics.returning_patients_count).to eq(5)
    end
  end

  describe '#non_returning_hypertensive_patients_count' do
    it 'return the number of patients enrolled as hypertensives that have not had a BP recorded in the period' do
      hypertensive_patients = create_list_in_period(:patient, 5, past_options)
      hypertensive_patients.each do |patient|
        create(:blood_pressure, :hypertensive, patient: patient, device_created_at: patient.device_created_at)
      end

      _returning_patients = hypertensive_patients.sample(2).each do |patient|
        create_in_period(:blood_pressure, current_options.merge(patient: patient))
      end

      analytics = Analytics::PatientSetAnalytics.new(Patient.all, from_time, to_time)
      expect(analytics.non_returning_hypertensive_patients_count).to eq(3)
    end
  end

  xdescribe '#non_returning_hypertensive_patients_count_per_month' do
    it 'return the number of patients enrolled as hypertensives that have not had a BP recorded per month' do
      expected_counts = {}
      4.times do |n|
        start_of_month = (Date.today - n.months).at_beginning_of_month

        patient = create_in_period :patient, from_time: start_of_month - 9.month, to_time: start_of_month.at_end_of_month - 9.months
        create :blood_pressure, patient: patient, device_created_at: patient.device_created_at

        date_key = start_of_month.to_date
        expected_counts[date_key] = 4
      end

      analytics = Analytics::PatientSetAnalytics.new(Patient.all, from_time, to_time)
      expect(analytics.non_returning_hypertensive_patients_count_per_month(4)).to include(expected_counts)
    end
  end

  describe '#control_rate' do
    context 'number of patients now under control / number of hypertensives patients recorded in cohort 9 months ago' do
      it 'returns the control rate for the set of patients in the give period' do
        hypertensive_patients_registered_9_months_ago = create_list_in_period(
          :patient, 5,
          from_time: from_time - 9.months,
          to_time: (to_time - 9.months).prev_day)

        hypertensive_patients_registered_9_months_ago.each do |patient|
          create_in_period(
            :blood_pressure,
            trait: :hypertensive, from_time: from_time - 9.months, to_time: to_time - 9.months,
            patient: patient)
        end

        patients_under_control_in_period = hypertensive_patients_registered_9_months_ago.sample(3)
        patients_under_control_in_period.each do |patient|
          create_in_period(
            :blood_pressure,
            trait: :under_control, from_time: from_time, to_time: to_time,
            patient: patient, facility: patient.registration_facility)
        end

        analytics = Analytics::PatientSetAnalytics.new(Patient.all, from_time, to_time)

        expect(analytics.control_rate)
          .to eq(control_rate: 60,
                 hypertensive_patients_in_cohort: 5,
                 patients_under_control_in_period: 3)
      end
    end
  end

  xdescribe '#blood_pressure_recored_per_week' do
    it 'returns the number of blood pressures recorded per week for a group of patients' do
      patients = create_list_in_period :patient, 5, from_time: 1.year.ago, to_time: to_time

      expected_counts = {}
      patients.each do |patient|
        n = rand(12)
        start_of_week = (Date.today - n.weeks).at_beginning_of_week
        create_in_period :blood_pressure,
                         from_time: start_of_week, to_time: start_of_week.at_end_of_week,
                         patient: patient

        date_key = start_of_week.prev_day.to_date
        if expected_counts[date_key].present?
          expected_counts[date_key] += 1
        else
          expected_counts[date_key] = 1
        end
      end

      analytics = Analytics::PatientSetAnalytics.new(Patient.all, from_time, to_time)
      expect(analytics.blood_pressures_recorded_per_week(12)).to include(expected_counts)
    end
  end
end