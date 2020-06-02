require "rails_helper"

RSpec.describe BloodPressureRollup, type: :model do
  context "counts of controlled per month" do
    it "can count things" do
      Timecop.freeze("March 15th 2020") do
        controlled_patient_1 = create(:patient)
        controlled_patient_2 = create(:patient)
        bp1 = create(:blood_pressure, :hypertensive, patient: controlled_patient_1, recorded_at: 20.days.ago)
        bp2 = create(:blood_pressure, :under_control, patient: controlled_patient_1, recorded_at: 20.days.ago)
        bp3 = create(:blood_pressure, :hypertensive, recorded_at: 1.days.ago)
        bp4 = create(:blood_pressure, :under_control, patient: controlled_patient_2, recorded_at: Time.parse("January 15th, 2020"))
        [bp1, bp2, bp3, bp4].each do |blood_pressure|
          BloodPressureRollup.from_blood_pressure(blood_pressure)
        end
        result = BloodPressureRollup.controlled_in_month(Time.parse("March 30 2020"))
        expect(result.first["count"]).to eq(2)
      end
    end
  end

  context "creating from blood pressure" do
    it "inserts initial blood pressure for month and quarter" do
      bp1 = create(:blood_pressure, diastolic: 110, systolic: 180, recorded_at: 2.days.ago)
      expect {
        BloodPressureRollup.from_blood_pressure(bp1)
      }.to change { BloodPressureRollup.count }.by(2)

      rollups = BloodPressureRollup.where(blood_pressure: bp1)
      rollups.each do |rollup|
        expect(rollup.diastolic).to eq(110)
        expect(rollup.systolic).to eq(180)
      end

      bp1 = create(:blood_pressure, diastolic: 110, systolic: 180, recorded_at: 2.days.ago)
      expect {
        BloodPressureRollup.from_blood_pressure(bp1)
      }.to change { BloodPressureRollup.count }.by(2)
    end

    it "updates more recent blood pressures" do
      Timecop.freeze("March 15th 2020") do
        patient = create(:patient)
        bp1 = create(:blood_pressure, patient: patient, diastolic: 110, systolic: 180, recorded_at: 7.days.ago)

        expect {
          BloodPressureRollup.from_blood_pressure(bp1)
        }.to change { BloodPressureRollup.count }.by(2)

        rollups = BloodPressureRollup.where(blood_pressure: bp1)
        expect(rollups.size).to eq(2)
        rollups.each do |rollup|
          expect(rollup.blood_pressure).to eq(bp1)
          expect(rollup.diastolic).to eq(110)
          expect(rollup.systolic).to eq(180)
          expect(rollup.year).to eq(2020)
        end
        expect(rollups.find_by(period_type: :month).period_number).to eq(3)
        expect(rollups.find_by(period_type: :quarter).period_number).to eq(1)

        bp2 = create(:blood_pressure, patient: patient, diastolic: 90, systolic: 150, recorded_at: 6.days.ago)

        expect {
          BloodPressureRollup.from_blood_pressure(bp2)
        }.to change { BloodPressureRollup.count }.by(0)

        rollups = BloodPressureRollup.where(blood_pressure: bp2)
        expect(rollups.size).to eq(2)
        rollups.each do |rollup|
          expect(rollup.blood_pressure).to eq(bp2)
          expect(rollup.diastolic).to eq(90)
          expect(rollup.systolic).to eq(150)
        end
      end
    end

    it "ignores older blood pressures for same period" do
      Timecop.freeze("March 15th 2020") do
        patient = create(:patient)
        bp1 = create(:blood_pressure, patient: patient, diastolic: 110, systolic: 180, recorded_at: 2.days.ago)

        expect {
          BloodPressureRollup.from_blood_pressure(bp1)
        }.to change { BloodPressureRollup.count }.by(2)

        bp2 = create(:blood_pressure, patient: patient, diastolic: 90, systolic: 150, recorded_at: 6.days.ago)

        expect {
          BloodPressureRollup.from_blood_pressure(bp2)
        }.to change { BloodPressureRollup.count }.by(0)

        expect(BloodPressureRollup.where(blood_pressure: bp2).count).to eq(0)
        rollups = BloodPressureRollup.where(patient: patient)
        rollups.each do |rollup|
          expect(rollup.diastolic).to eq(110)
          expect(rollup.systolic).to eq(180)
        end
      end
    end

    it "inserts a new blood pressure for the month and updates the quarter blood pressure" do
      Timecop.freeze("March 15th 2020") do
        patient = create(:patient)
        bp1 = create(:blood_pressure, patient: patient, diastolic: 110, systolic: 180, recorded_at: 1.month.ago)

        expect {
          BloodPressureRollup.from_blood_pressure(bp1)
        }.to change { BloodPressureRollup.count }.by(2)

        bp2 = create(:blood_pressure, patient: patient, diastolic: 120, systolic: 150, recorded_at: 1.days.ago)
        expect {
          BloodPressureRollup.from_blood_pressure(bp2)
        }.to change { BloodPressureRollup.count }.by(1)

        rollups = BloodPressureRollup.where(patient: patient)
        rollups.month.where(period_number: 2).each do |rollup|
          expect(rollup.diastolic).to eq(110)
          expect(rollup.systolic).to eq(180)
        end
        rollups.month.where(period_number: 3).each do |rollup|
          expect(rollup.diastolic).to eq(120)
          expect(rollup.systolic).to eq(150)
        end
        rollups.quarter.where(period_number: 1).each do |rollup|
          expect(rollup.diastolic).to eq(120)
          expect(rollup.systolic).to eq(150)
        end
      end
    end

    it "removes old rollups for an updated blood pressure that gets back-dated" do
      patient = create(:patient)
      Timecop.freeze("June 5th 2020") do
        june_4th_bp = create(:blood_pressure, patient: patient, diastolic: 100, systolic: 170, recorded_at: 1.day.ago)
        bp1 = create(:blood_pressure, patient: patient, diastolic: 110, systolic: 180, recorded_at: Time.current)

        expect {
          BloodPressureRollup.from_blood_pressure(june_4th_bp)
          BloodPressureRollup.from_blood_pressure(bp1)
        }.to change { BloodPressureRollup.count }.by(2)
        rollup = BloodPressureRollup.month.find_by(patient: patient, period_number: 6)

        expect(rollup.diastolic).to eq(110)
        expect(rollup.systolic).to eq(180)

        bp1.update!(recorded_at: 25.days.ago, merge_status: :updated)
        BloodPressureRollup.from_blood_pressure(bp1)

        rollup = BloodPressureRollup.month.reload.find_by(patient: patient, period_number: 6)

        expect(rollup.diastolic).to eq(100)
        expect(rollup.systolic).to eq(170)
      end
    end
  end
end
