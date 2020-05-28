require "rails_helper"

RSpec.describe BloodPressureRollup, type: :model do
  it "upserts records by month and by quarter" do
    bp1 = create(:blood_pressure, diastolic: 110, systolic: 180)
    expect {
      BloodPressureRollup.from_blood_pressure(bp1)
    }.to change { BloodPressureRollup.count }.by(2)

    rollups = BloodPressureRollup.where(blood_pressure: bp1)
    rollups.each do |rollup|
      expect(rollup.diastolic).to eq(110)
      expect(rollup.systolic).to eq(180)
    end

    expect {
      BloodPressureRollup.from_blood_pressure(bp1)
    }.to change { BloodPressureRollup.count }.by(0)

    bp1.diastolic = 80
    bp1.systolic = 150
    bp1.save!

    expect {
      BloodPressureRollup.from_blood_pressure(bp1)
    }.to change { BloodPressureRollup.count }.by(0)

    rollups = BloodPressureRollup.where(blood_pressure: bp1)
    rollups.each do |rollup|
      expect(rollup.diastolic).to eq(80)
      expect(rollup.systolic).to eq(150)
    end
  end

end
