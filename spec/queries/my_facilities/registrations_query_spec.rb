require 'rails_helper'

RSpec.describe MyFacilities::RegistrationsQuery do
  context 'Registrations queries' do
    describe '#total_registrations' do
      let!(:registrations_query) { described_class.new }

      let!(:included_timestamps) { [1.year.ago, 2.years.ago, 1.day.ago, 1.months.ago] }
      let!(:patients) do
        included_timestamps.map do |recorded_at|
          create(:patient, recorded_at: recorded_at)
        end
      end
      let!(:non_htn_patient) { create(:patient, :without_hypertension, recorded_at: included_timestamps.first) }

      specify { expect(registrations_query.total_registrations.count).to eq(patients.count) }
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
        let!(:non_htn_patient) { create(:patient, :without_hypertension, recorded_at: included_timestamps.first) }

        before do
          ActiveRecord::Base.transaction do
            ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'")
            PatientRegistrationsPerDayPerFacility.refresh
          end
        end

        context 'considers only htn diagnosed patients' do
          specify { expect(registrations_query.registrations.count).to eq(included_timestamps.count) }
        end
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
        let!(:non_htn_patient) { create(:patient, :without_hypertension, recorded_at: included_timestamps.first) }

        before do
          ActiveRecord::Base.transaction do
            ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'")
            PatientRegistrationsPerDayPerFacility.refresh
          end
        end

        context 'considers only htn diagnosed patients' do
          specify { expect(registrations_query.registrations.count).to eq(included_timestamps.count) }
        end
      end

      context 'daily' do
        let!(:registrations_query) { described_class.new(period: :day, last_n: 7) }

        let!(:included_timestamps) { [1.day.ago, 7.days.ago] }
        let!(:excluded_timestamps) { [8.days.ago] }
        let!(:patients) do
          (included_timestamps + excluded_timestamps).map { |recorded_at| create(:patient, recorded_at: recorded_at) }
        end
        let!(:non_htn_patient) { create(:patient, :without_hypertension, recorded_at: included_timestamps.first) }

        before do
          ActiveRecord::Base.transaction do
            ActiveRecord::Base.connection.execute("SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'")
            PatientRegistrationsPerDayPerFacility.refresh
          end
        end

        context 'considers only htn diagnosed patients' do
          specify { expect(registrations_query.registrations.count).to eq(included_timestamps.count) }
        end
      end
    end
  end
end
