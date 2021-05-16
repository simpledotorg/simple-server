require "rails_helper"

RSpec.describe BPMeasuresQuery do
  let(:user) { create(:user) }

  it "works" do
    facility = create(:facility)
    Timecop.freeze("May 5th 2021") do
      create(:blood_pressure, facility: facility, recorded_at: 4.months.ago, user: user)
      create(:blood_pressure, facility: facility, recorded_at: 2.months.ago, user: user)
      expected = {
        Period.month("January 2021") => 1,
        Period.month("February 2021") => 0,
        Period.month("March 2021") => 1,

      }
      expect(described_class.new.count(facility, :month)).to eq(expected)
    end
  end

  it "can be grouped further" do
    [ june_1, june_2, june_3, july_1, aug_1, aug_2 ].each do |date|
      patient = create(:patient, :hypertension, recorded_at: long_ago)
      create(:blood_pressure, patient: patient, facility: facility_1, recorded_at: date)
    end

    [ june_1, july_1, july_3, aug_1, aug_2 ].each do |date|
      patient = create(:patient, :hypertension, recorded_at: long_ago)
      create(:blood_pressure, patient: patient, facility: facility_2, recorded_at: date)
    end

    activity_service = ActivityService.new(facility_group, group: BloodPressure.arel_table[:facility_id])

    Timecop.freeze(aug_3) do
      expect(described_class.new.count(facility_group, group: :facility_id).to eq(
        [june_1, facility_1.id] => 3,
        [july_1, facility_1.id] => 1,
        [aug_1, facility_1.id] => 2,
        [june_1, facility_2.id] => 1,
        [july_1, facility_2.id] => 2,
        [aug_1, facility_2.id] => 2
      )
    end
  end
end