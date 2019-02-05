require 'rails_helper'

RSpec.describe Analytics::FacilityAnalytics do
  let(:organization) { create :organization }
  let(:facility_group) { create :facility_group, organization: organization }
  let(:facility) { create :facility, facility_group: facility_group }
  let(:months_previous) { 6 }

  before :each do
    months_previous.times do |n|
      create_list :patient, n, registration_facility: facility, device_created_at: (n - 1).months.ago
    end
  end

  describe 'contains analytics for a single facility n previous months' do
    let(:facility_analytics) { Analytics::FacilityAnalytics.new(facility, months_previous: months_previous) }

    describe '#newly_enrolled_patients_per_month' do
      it 'has the count of patients enrolled per month for last months_previous months' do
        expected_patients_count = (1...months_previous).map { |n| [(n - 1).months.ago.at_beginning_of_month.to_date, n] }.to_h
        expect(facility_analytics.newly_enrolled_patients_per_month)
          .to include(expected_patients_count)
      end
    end

    describe '#newly_enrolled_patients_this_month' do
      it 'has the count of patients enrolled this month' do
        expect(facility_analytics.newly_enrolled_patients_this_month).to eq(1)
      end
    end

    describe '#returning_patients_count_this_month' do
      let(:returning_patients) { create_list :patient, 10, registration_facility: facility }
      let!(:other_patients) { create_list :patient, 10, registration_facility: facility }

      before :each do
        returning_patients.each do |patient|
          create :blood_pressure, facility: facility, patient: patient
        end
      end

      it 'has the number of patients returning this month' do
        expect(facility_analytics.returning_patients_count_this_month).to eq(10)
      end
    end

    describe '#unique_patients_recorded_per_month' do
      before :each do
        months_previous.times do |n|
          patients = create_list :patient, n
          patients.each do |patient|
            create_list :blood_pressure, n, patient: patient, facility: facility, device_created_at: n.months.ago
          end
        end
      end

      it 'has the number of unique patients recorded this month' do
        expected_patients_count = (1...months_previous).map { |n| [n.months.ago.at_beginning_of_month.to_date, n] }.to_h
        expect(facility_analytics.unique_patients_recorded_per_month).to include(expected_patients_count)
      end
    end

    describe '#overdue_patients_count_per_month' do
      before :each do
        months_previous.times do |n|
          patients = create_list :patient, n
          patients.each do |patient|
            create_list :blood_pressure, n, patient: patient, facility: facility, device_created_at: (n.months.ago - 90.days)
          end
        end
      end

      it 'has the number of patients overdue for more than 90 days per month' do
        expected_patients_count = (1...months_previous).map { |n| [n.months.ago.at_beginning_of_month.to_date, n] }.to_h
        expect(facility_analytics.unique_patients_recorded_per_month).to include(expected_patients_count)
      end
    end
  end
end
