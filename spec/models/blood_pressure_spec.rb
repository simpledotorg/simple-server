require "rails_helper"

RSpec.describe BloodPressure, type: :model do
  describe "Validations" do
    it_behaves_like "a record that validates device timestamps"
  end

  describe "Associations" do
    it { should belong_to(:facility).optional }
    it { should belong_to(:patient).optional }
    it { should belong_to(:user).optional }
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  context "utility methods" do
    let(:bp_normal) { create(:blood_pressure, systolic: 120, diastolic: 80) }
    let(:bp_high_systolic) { create(:blood_pressure, systolic: 140, diastolic: 80) }
    let(:bp_high_diastolic) { create(:blood_pressure, systolic: 120, diastolic: 90) }
    let(:bp_high_both) { create(:blood_pressure, systolic: 150, diastolic: 100) }

    describe ".hypertensive" do
      it "only includes hypertensive BPs" do
        expect(BloodPressure.hypertensive).to include(bp_high_systolic, bp_high_diastolic, bp_high_both)
        expect(BloodPressure.hypertensive).not_to include(bp_normal)
      end
    end

    describe ".under_control" do
      it "only includes BPs under control" do
        expect(BloodPressure.under_control).to include(bp_normal)
        expect(BloodPressure.under_control).not_to include(bp_high_systolic, bp_high_diastolic, bp_high_both)
      end
    end

    describe "#under_control?" do
      it "returns true if both systolic and diastolic are under control" do
        expect(bp_normal).to be_under_control
      end

      it "returns false if systolic is high" do
        expect(bp_high_systolic).not_to be_under_control
      end

      it "returns false if diastolic is high" do
        expect(bp_high_diastolic).not_to be_under_control
      end

      it "returns false if both systolic and diastolic are high" do
        expect(bp_high_both).not_to be_under_control
      end
    end

    describe "#critical?" do
      [{systolic: 181, diastolic: 111},
        {systolic: 181, diastolic: 109},
        {systolic: 179, diastolic: 111}].each do |row|
        it "returns true if bp is in a critical state" do
          bp = create(:blood_pressure, systolic: row[:systolic], diastolic: row[:diastolic])
          expect(bp).to be_critical
        end
      end

      it "returns false if bp is not in a critical state" do
        bp = create(:blood_pressure, systolic: 179, diastolic: 109)
        expect(bp).not_to be_critical
      end
    end

    describe "#hypertensive?" do
      [{systolic: 140, diastolic: 80},
        {systolic: 120, diastolic: 90},
        {systolic: 180, diastolic: 120}].each do |row|
        it "returns true if bp is high" do
          bp = create(:blood_pressure, systolic: row[:systolic], diastolic: row[:diastolic])
          expect(bp).to be_hypertensive
        end
      end

      it "returns false if bp is not high" do
        bp = create(:blood_pressure, systolic: 139, diastolic: 89)
        expect(bp).not_to be_hypertensive
      end
    end

    describe "#recorded_days_ago" do
      it "returns 2 days" do
        bp_recorded_2_days_ago = create(:blood_pressure, device_created_at: 2.days.ago)

        expect(bp_recorded_2_days_ago.recorded_days_ago).to eq(2)
      end
    end

    describe "#to_s" do
      it "is systolic/diastolic" do
        expect(bp_normal.to_s).to eq("120/80")
      end
    end
  end

  context "recent_in_month" do
    it "returns most recent BP for patients in a month" do
      patient = create(:patient)
      Timecop.freeze("June 30th 2020") do
        bp1 = create(:blood_pressure, patient: patient, recorded_at: 3.days.ago)
        bp2 = create(:blood_pressure, patient: patient, recorded_at: 2.months.ago)
        bp3 = create(:blood_pressure, patient: patient, recorded_at: 1.days.ago)
        other_bp = create(:blood_pressure, recorded_at: 10.days.ago)
        recent = BloodPressure.recent_in_month(Time.current)
        expect(recent).to match_array([bp3, other_bp])
      end
    end
  end

  context "anonymised data for blood pressures" do
    describe "anonymized_data" do
      it "correctly retrieves the anonymised data for the blood pressure" do
        blood_pressure = create(:blood_pressure)

        anonymised_data =
          {id: Hashable.hash_uuid(blood_pressure.id),
           patient_id: Hashable.hash_uuid(blood_pressure.patient_id),
           created_at: blood_pressure.created_at,
           bp_date: blood_pressure.recorded_at,
           registration_facility_name: blood_pressure.facility.name,
           user_id: Hashable.hash_uuid(blood_pressure.user.id),
           bp_systolic: blood_pressure.systolic,
           bp_diastolic: blood_pressure.diastolic}

        expect(blood_pressure.anonymized_data).to eq anonymised_data
      end
    end
  end
end
