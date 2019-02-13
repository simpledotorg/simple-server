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
        expect(facility_analytics.newly_enrolled_patients_per_month)
          .to include(1)
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

    describe '#all_time_patients_count' do
      it 'has the number of all patients registered at the facility' do
        expect(facility_analytics.all_time_patients_count).to eq(15)
      end
    end

    describe '#hypertensive_patients_in_cohort' do
      let(:hypertensive_patients_registered_9_months) { create_list :patient, 3, device_created_at: 9.months.ago }
      let(:non_hypertensive_patients_registered_9_months) { create_list :patient, 3, device_created_at: 9.months.ago }
      let(:hypertensive_patients_registered_5_months) { create_list :patient, 3, device_created_at: 5.months.ago }

      before :each do
        hypertensive_patients_registered_9_months.each do |patient|
          create :blood_pressure, :hypertensive, patient: patient, facility: facility, device_created_at: patient.device_created_at
        end

        non_hypertensive_patients_registered_9_months.each do |patient|
          create :blood_pressure, :under_control, patient: patient, facility: facility, device_created_at: patient.device_created_at
        end

        hypertensive_patients_registered_5_months.each do |patient|
          create :blood_pressure, :hypertensive, patient: patient, facility: facility, device_created_at: patient.device_created_at
        end
      end
      it 'has the patients that were measured hypertensive n months ago during an equivalent period' do
        expect(facility_analytics.hypertensive_patients_in_cohort(
          since: Date.today.at_beginning_of_month,
          upto: Date.today.at_end_of_month,
          delta: 9.months).map(&:patient))
          .to match_array(hypertensive_patients_registered_9_months)
      end
    end

    describe '#controlled_patients_for_facility' do
      let(:hypertensive_patients_registered_9_months) { create_list :patient, 10, device_created_at: 9.months.ago }
      let(:patients_under_control_currently) { hypertensive_patients_registered_9_months.take(5) }

      before :each do
        hypertensive_patients_registered_9_months.map do |patient|
          create :blood_pressure, :hypertensive, patient: patient, facility: facility, device_created_at: 9.months.ago
        end

        patients_under_control_currently.map do |patient|
          create :blood_pressure, :under_control, patient: patient, facility: facility, device_created_at: Time.now
        end
      end

      it 'should contain the list of patients under control' do
        expect(facility_analytics.controlled_patients_for_facility(hypertensive_patients_registered_9_months.map(&:id)))
          .to match_array(patients_under_control_currently)
      end
    end

    describe '#control_rate_for_period' do
      let(:hypertensive_patients_registered_9_months) { create_list :patient, 10, device_created_at: 9.months.ago }
      let(:patients_under_control_currently) { hypertensive_patients_registered_9_months.take(5) }

      before :each do
        hypertensive_patients_registered_9_months.map do |patient|
          create :blood_pressure, :hypertensive, patient: patient, facility: facility, device_created_at: 9.months.ago
        end

        patients_under_control_currently.map do |patient|
          create :blood_pressure, :under_control, patient: patient, facility: facility, device_created_at: Time.now
        end
      end

      it 'should calculate the control rate for the given period' do
        expect(facility_analytics.control_rate_for_period(Date.today.at_beginning_of_month, Date.today.at_end_of_month))
          .to eq(50)
      end
    end

    describe '#control_rate_per_month' do
      let(:hypertensive_patients_registered_9_months) { create_list :patient, 10, device_created_at: 9.months.ago }
      let(:patients_under_control_currently) { hypertensive_patients_registered_9_months.take(5) }

      before :each do
        hypertensive_patients_registered_9_months.map do |patient|
          create :blood_pressure, :hypertensive, patient: patient, facility: facility, device_created_at: 9.months.ago
        end

        patients_under_control_currently.map do |patient|
          create :blood_pressure, :under_control, patient: patient, facility: facility, device_created_at: Time.now
        end
      end


      it 'returns a hash with the control rates for the facility per month' do
        4.times do |n|
          hypertensive_patients = create_list :patient, 10, device_created_at: (n + 9).months.ago
          hypertensive_patients.each do |patient|
            create :blood_pressure, :hypertensive, patient: patient, facility: facility, device_created_at: patient.device_created_at
          end
          patients_under_control_currently = hypertensive_patients.take(n)
          patients_under_control_currently.each do |patient|
            create :blood_pressure, :under_control, patient: patient, facility: facility, device_created_at: n.months.ago
          end
        end

        expect(facility_analytics.control_rate_per_month(4).map { |k, v| [k, v] }.to_h)
          .to eq({ 1.month.ago => 10,
                   2.months.ago => 20,
                   3.months.ago => 30,
                   4.months.ago => 0 }.map { |k,v| [k.at_beginning_of_month, v]}.to_h)
      end
    end
  end
end
