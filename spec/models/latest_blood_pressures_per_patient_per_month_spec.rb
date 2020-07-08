require "rails_helper"

RSpec.describe LatestBloodPressuresPerPatientPerMonth, type: :model do
  describe "Associations" do
    it { should belong_to(:patient) }
  end

  describe "Materialized view query" do
    Timecop.travel("1 Oct 2019") do
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
        facilities.map { |facility|
          months.map do |month|
            patients.map do |patient|
              create_list(:blood_pressure, 2, facility: facility, recorded_at: month, patient: patient)
            end
          end
        }.flatten
      end

      let!(:query_results) do
        LatestBloodPressuresPerPatientPerMonth.refresh
        LatestBloodPressuresPerPatientPerMonth.all
      end
    end

    it "returns a row per patient per month" do
      expect(query_results.count).to eq(6)
    end
    it "returns at least one row per patient" do
      expect(query_results.pluck(:patient_id).uniq).to match_array(patients.map(&:id))
    end
  end

  describe "Responsible facility calculation" do
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

    it "contains the latest bp per month only" do
      expect(query_results.all.map(&:bp_id)).not_to include(bp_1.id)
    end

    it "doesn't have a responsible facility for a patient's second bp if their last bp was in the same month" do
      expect(query_results.where(bp_id: bp_2.id).first.responsible_facility_id).to be_nil
    end

    it "doesn't have a responsible facility for a patient's first bp" do
      expect(query_results.where(bp_id: bp_4.id).first.responsible_facility_id).to be_nil
    end

    it "has the responsible facility be last facility where a bp was recorded in the previous month" do
      expect(query_results.where(bp_id: bp_3.id).first.responsible_facility_id).to eq(facilities.second.id)
    end

    it "has the responsible facility be last facility where a bp was recorded in the previous month" do
      expect(query_results.where(bp_id: bp_5.id).first.responsible_facility_id).to eq(facilities.first.id)
    end

    it "has the responsible facility be last facility where a bp was recorded in any prior month" do
      expect(query_results.where(bp_id: bp_7.id).first.responsible_facility_id).to eq(facilities.first.id)
    end
  end

  describe "patient status and medical history fields" do
    fit "stores and updates patient status" do
      patient_1 = create(:patient, status: :migrated)
      patient_2 = create(:patient, status: :dead)

      create(:blood_pressure, patient: patient_1)
      create(:blood_pressure, patient: patient_2)

      LatestBloodPressuresPerPatientPerMonth.refresh

      bp_per_month_1 = LatestBloodPressuresPerPatientPerMonth.find_by!(patient_id: patient_1.id)
      expect(bp_per_month_1.patient_status).to eq("migrated")
      bp_per_month_2 = LatestBloodPressuresPerPatientPerMonth.find_by!(patient_id: patient_2.id)
      expect(bp_per_month_2.patient_status).to eq("dead")

      patient_1.update!(status: :active)

      LatestBloodPressuresPerPatientPerMonth.refresh

      bp_per_month_1 = LatestBloodPressuresPerPatientPerMonth.find_by!(patient_id: patient_1.id)
      expect(bp_per_month_1.patient_status).to eq("active")
    end

    it "stores and updates medical_history_hypertension" do
      patient_1 = create(:patient)
      patient_2 = create(:patient, :without_hypertension)
      patient_3 = create(:patient, :without_medical_history)

      create(:blood_pressure, patient: patient_1)
      create(:blood_pressure, patient: patient_2)
      create(:blood_pressure, patient: patient_3)

      LatestBloodPressuresPerPatientPerMonth.refresh

      bp_per_month_1 = LatestBloodPressuresPerPatientPerMonth.find_by!(patient_id: patient_1.id)
      expect(bp_per_month_1.medical_history_hypertension).to eq("yes")
      bp_per_month_2 = LatestBloodPressuresPerPatientPerMonth.find_by!(patient_id: patient_2.id)
      expect(bp_per_month_2.medical_history_hypertension).to eq("no")
      bp_per_month_3 = LatestBloodPressuresPerPatientPerMonth.find_by!(patient_id: patient_3.id)
      expect(bp_per_month_3.medical_history_hypertension).to be_nil
    end
  end
end
