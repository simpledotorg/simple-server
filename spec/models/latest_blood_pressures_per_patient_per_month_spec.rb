require "rails_helper"

RSpec.describe LatestBloodPressuresPerPatientPerMonth, type: :model do
  def refresh_views
    described_class.refresh
  end

  describe "Associations" do
    it { should belong_to(:patient) }
  end

  describe "Scopes" do
    describe ".ltfu_as_of" do
      it "includes BP for patient who is LTFU" do
        ltfu_patient = Timecop.freeze(2.years.ago) { create(:patient) }
        Timecop.freeze(2.years.ago) { create(:blood_pressure, patient: ltfu_patient) }
        refresh_views

        expect(described_class.ltfu_as_of(Time.current).pluck(:patient_id)).to include(ltfu_patient.id)
      end

      it "excludes BP for patient who is not LTFU" do
        not_ltfu_patient = Timecop.freeze(2.years.ago) { create(:patient) }
        Timecop.freeze(6.months.ago) { create(:blood_pressure, patient: not_ltfu_patient) }
        refresh_views

        expect(described_class.ltfu_as_of(Time.current)).not_to include(not_ltfu_patient)
      end
    end

    describe ".not_ltfu_as_of" do
      it "excludes patient who is LTFU" do
        ltfu_patient = Timecop.freeze(2.years.ago) { create(:patient) }
        Timecop.freeze(2.years.ago) { create(:blood_pressure, patient: ltfu_patient) }
        refresh_views

        expect(described_class.not_ltfu_as_of(Time.current)).not_to include(ltfu_patient)
      end

      it "includes patient who is not LTFU" do
        not_ltfu_patient = Timecop.freeze(2.years.ago) { create(:patient) }
        Timecop.freeze(6.months.ago) { create(:blood_pressure, patient: not_ltfu_patient) }
        refresh_views

        expect(described_class.not_ltfu_as_of(Time.current).pluck(:patient_id)).to include(not_ltfu_patient.id)
      end
    end
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

  describe "assigned facility" do
    let!(:facility) { create(:facility) }
    let!(:patient) { create(:patient, assigned_facility: facility) }
    let!(:blood_pressure) { create(:blood_pressure, patient: patient) }
    before { described_class.refresh }

    it "stores the assigned facility" do
      expect(described_class.find_by_bp_id(blood_pressure.id).assigned_facility_id).to eq facility.id
    end
  end

  describe "patient status and medical history fields" do
    it "stores and updates patient status" do
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
