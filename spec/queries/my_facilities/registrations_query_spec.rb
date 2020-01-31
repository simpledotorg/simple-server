require 'rails_helper'

RSpec.describe MyFacilities::RegistrationsQuery do
  context 'Registrations queries' do
    describe '#all_time_registrations' do
      let!(:registrations_query) { described_class.new }

      let!(:patient_registration_timestamps) { [1.day.ago, 1.month.ago, 1.year.ago, 2.years.ago] }
      let!(:patients) do
        patient_registration_timestamps.map { |recorded_at| create(:patient, recorded_at: recorded_at) }
      end
      let!(:blood_pressures) do
        patients.map { |patient| create(:blood_pressure, patient: patient, facility: patient.registration_facility) }
      end

      before do
        ActiveRecord::Base.transaction do
          ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{ENV['ANALYTICS_TIME_ZONE']}'")
          LatestBloodPressuresPerPatientPerMonth.refresh
          LatestBloodPressuresPerPatient.refresh
        end
      end

      specify { expect(registrations_query.all_time_registrations.count).to eq(4) }
    end

    describe '#cohort_registrations' do
      context 'quarterly' do
        let!(:registrations_query) { described_class.new(period: :quarter, include_quarters: 3) }

        let!(:patient_registration_timestamps) { [1.month.ago, 4.months.ago, 11.months.ago] }
        let!(:patients) do
          patient_registration_timestamps.map { |recorded_at| create(:patient, recorded_at: recorded_at) }
        end
        let!(:blood_pressures) do
          patients.map { |patient| create(:blood_pressure, patient: patient, facility: patient.registration_facility) }
        end

        before do
          ActiveRecord::Base.transaction do
            ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{ENV['ANALYTICS_TIME_ZONE']}'")
            PatientRegistrationsPerDayPerFacility.refresh
          end
        end

        specify { pp LatestBloodPressuresPerPatient.all
          expect(registrations_query.registrations.count).to eq(2) }
      end

      context 'monthly' do
        let!(:registrations_query) { described_class.new(period: :month, include_months: 3) }

        let!(:patient_registration_timestamps) { [1.month.ago, 3.months.ago, 1.year.ago] }
        let!(:patients) do
          patient_registration_timestamps.map { |recorded_at| create(:patient, recorded_at: recorded_at) }
        end
        let!(:blood_pressures) do
          patients.map { |patient| create(:blood_pressure, patient: patient, facility: patient.registration_facility) }
        end

        before do
          ActiveRecord::Base.transaction do
            ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{ENV['ANALYTICS_TIME_ZONE']}'")
            PatientRegistrationsPerDayPerFacility.refresh
          end
        end

        specify { expect(registrations_query.registrations.count).to eq(2) }
      end

      context 'daily' do
        let!(:registrations_query) { described_class.new(period: :day, include_days: 7) }

        let!(:patient_registration_timestamps) { [1.day.ago, 7.days.ago, 8.days.ago] }
        let!(:patients) do
          patient_registration_timestamps.map { |recorded_at| create(:patient, recorded_at: recorded_at) }
        end
        let!(:blood_pressures) do
          patients.map { |patient| create(:blood_pressure, patient: patient, facility: patient.registration_facility) }
        end

        before do
          ActiveRecord::Base.transaction do
            ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{ENV['ANALYTICS_TIME_ZONE']}'")
            PatientRegistrationsPerDayPerFacility.refresh
          end
        end

        specify { expect(registrations_query.registrations.count).to eq(3) }
      end
    end
  end
end
