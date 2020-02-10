require 'rails_helper'

RSpec.describe LatestBloodPressuresPerPatientPerMonth, type: :model do
  describe 'Associations' do
    it { should belong_to(:patient) }
  end

  describe 'a' do
    Timecop.travel('1 Oct 2019') do
      let!(:facilities) { create_list(:facility, 2) }
      let!(:months) do
        [1, 2, 3].map { |n| n.months.ago }
      end
      let!(:patients) do
        facilities.map do |facility|
          create(:patient, registration_facility: facility)
        end
      end

      let!(:blood_pressures) do
        facilities.map do |facility|
          months.map do |month|
            patients.map do |patient|
              create_list(:blood_pressure, 2, facility: facility, recorded_at: month, patient: patient)
            end
          end
        end.flatten
      end

      let!(:query_results) do
        LatestBloodPressuresPerPatientPerMonth.refresh
        LatestBloodPressuresPerPatientPerMonth.all
      end
    end

    it 'should return a row per patient per month' do
      expect(query_results.count).to eq(6)
    end
    it 'should return at least one row per patient' do
      expect(query_results.pluck(:patient_id).uniq).to match_array(patients.map(&:id))
    end
  end

  describe 'Responsible facility calculation' do
    let!(:facilities) { create_list(:facility, 2) }
    let!(:months) do
      [2, 1, 0].map { |n| n.months.ago.beginning_of_month }
    end
    let!(:patients) do
      facilities.map do |facility|
        create(:patient, registration_facility: facility, recorded_at: 3.months.ago)
      end
    end

    let!(:patient_3) { create(:patient, registration_facility: facilities.first, recorded_at: months.first - 2.months) }

    let!(:bp_1) { create(:blood_pressure, facility: facilities.first, patient: patients.first, recorded_at: months.first) }
    let!(:bp_2) { create(:blood_pressure, facility: facilities.second, patient: patients.first, recorded_at: months.first + 10.days) }
    let!(:bp_3) { create(:blood_pressure, facility: facilities.second, patient: patients.first, recorded_at: months.second) }
    let!(:bp_4) { create(:blood_pressure, facility: facilities.first, patient: patients.second, recorded_at: months.first) }
    let!(:bp_5) { create(:blood_pressure, facility: facilities.second, patient: patients.second, recorded_at: months.second) }
    let!(:bp_6) { create(:blood_pressure, facility: facilities.first, patient: patient_3, recorded_at: months.first) }
    let!(:bp_7) { create(:blood_pressure, facility: facilities.first, patient: patient_3, recorded_at: months.third) }

    let!(:query_results) do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatientPerMonth
    end


    it 'should contain the latest bp per month only' do
      expect(query_results.all.map(&:bp_id)).not_to include(bp_1.id)
    end

    it "shouldn't have a responsible facility for a patient's second bp if their last bp was in the same month" do
      expect(query_results.where(bp_id: bp_2.id).first.responsible_facility_id).to be_nil
    end

    it "shouldn't have a responsible facility for a patient's first bp" do
      expect(query_results.where(bp_id: bp_4.id).first.responsible_facility_id).to be_nil
    end

    it 'should have the responsible facility be last facility where a bp was recorded in the previous month' do
      expect(query_results.where(bp_id: bp_3.id).first.responsible_facility_id).to eq(facilities.second.id)
    end

    it 'should have the responsible facility be last facility where a bp was recorded in the previous month' do
      expect(query_results.where(bp_id: bp_5.id).first.responsible_facility_id).to eq(facilities.first.id)
    end

    it 'should have the responsible facility be last facility where a bp was recorded in any prior month' do
      expect(query_results.where(bp_id: bp_7.id).first.responsible_facility_id).to eq(facilities.first.id)
    end
  end
end

