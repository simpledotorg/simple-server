require 'rails_helper'

RSpec.describe MyFacilities::RegistrationsQuery do
  context 'Registrations queries' do
    describe '#all_time_registrations' do
      let!(:registrations_query) { described_class.new }

      let!(:included_timestamps) { [1.year.ago, 2.years.ago] }
      let!(:excluded_timestamps) { [1.day.ago, 1.months.ago] }
      let!(:patients) do
        (included_timestamps + excluded_timestamps).map do |recorded_at|
          create(:patient, recorded_at: recorded_at)
        end
      end
      let!(:blood_pressures) do
        patients.map { |patient| create(:blood_pressure, patient: patient, facility: patient.registration_facility) }
      end

      before do
        ActiveRecord::Base.transaction do
          ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'")
          LatestBloodPressuresPerPatientPerMonth.refresh
          LatestBloodPressuresPerPatient.refresh
        end
      end

      specify { expect(registrations_query.all_time_registrations.count).to eq(included_timestamps.count) }
    end

    describe '#registrations' do
      context 'quarterly' do
        let!(:registrations_query) { described_class.new(period: :quarter, last_n: 3) }

        let!(:included_timestamps) { [1.month.ago, 4.months.ago] }
        let!(:excluded_timestamps) { [11.months.ago] }
        let!(:patients) do
          (included_timestamps + excluded_timestamps).map do |recorded_at|
            create(:patient, recorded_at: recorded_at)
          end
        end
        let!(:blood_pressures) do
          patients.map { |patient| create(:blood_pressure, patient: patient, facility: patient.registration_facility) }
        end

        before do
          ActiveRecord::Base.transaction do
            ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'")
            PatientRegistrationsPerDayPerFacility.refresh
          end
        end

        specify { expect(registrations_query.registrations.count).to eq(included_timestamps.count) }
      end

      context 'monthly' do
        let!(:registrations_query) { described_class.new(period: :month, last_n: 3) }

        let!(:included_timestamps) { [1.month.ago, 2.months.ago] }
        let!(:excluded_timestamps) { [12.months.ago] }
        let!(:patients) do
          (included_timestamps + excluded_timestamps).map do |recorded_at|
            create(:patient, recorded_at: recorded_at)
          end
        end
        let!(:blood_pressures) do
          patients.map { |patient| create(:blood_pressure, patient: patient, facility: patient.registration_facility) }
        end

        before do
          ActiveRecord::Base.transaction do
            ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'")
            PatientRegistrationsPerDayPerFacility.refresh
          end
        end

        specify { expect(registrations_query.registrations.count).to eq(included_timestamps.count) }
      end

      context 'daily' do
        let!(:registrations_query) { described_class.new(period: :day, last_n: 7) }

        let!(:included_timestamps) { [1.day.ago, 7.days.ago] }
        let!(:excluded_timestamps) { [8.days.ago] }
        let!(:patients) do
          (included_timestamps + excluded_timestamps).map { |recorded_at| create(:patient, recorded_at: recorded_at) }
        end
        let!(:blood_pressures) do
          patients.map { |patient| create(:blood_pressure, patient: patient, facility: patient.registration_facility) }
        end

        before do
          ActiveRecord::Base.transaction do
            ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'")
            PatientRegistrationsPerDayPerFacility.refresh
          end
        end

        specify { expect(registrations_query.registrations.count).to eq(included_timestamps.count) }
      end
    end
  end
end
