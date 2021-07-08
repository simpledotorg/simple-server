require "rails_helper"

RSpec.describe BPMeasuresQuery do
  let(:user_1) { create(:user) }
  let(:user_2) { create(:user) }

  it "returns counts of BPs per period" do
    facility = create(:facility)
    Timecop.freeze("May 5th 2021") do
      create(:blood_pressure, facility: facility, recorded_at: 4.months.ago, user: user_1)
      create(:blood_pressure, facility: facility, recorded_at: 2.months.ago, user: user_2)
      expected = {
        Period.month("January 2021") => 1,
        Period.month("February 2021") => 0,
        Period.month("March 2021") => 1

      }
      expect(described_class.new.count(facility, :month)).to eq(expected)
    end
  end

  it "handles period boundaries correctly, taking into account time zones" do
    facility = create(:facility)
    end_of_jan = Time.zone.parse("January 31st 23:59:59 IST")
    beg_of_feb = Time.zone.parse("February 1st 00:00:00 IST")

    create(:blood_pressure, facility: facility, recorded_at: end_of_jan, user: user_1)
    create(:blood_pressure, facility: facility, recorded_at: beg_of_feb, user: user_2)

    with_reporting_time_zone do
      expected = {
        Period.month("January 2021") => 1,
        Period.month("February 2021") => 1
      }
      expect(described_class.new.count(facility, :month)).to eq(expected)
    end
  end

  it "can return counts of BPs per period per user" do
    facility = create(:facility)
    Timecop.freeze("May 5th 2021") do
      patient = create(:patient)
      create(:blood_pressure, facility: facility, recorded_at: 4.months.ago, user: user_1)
      create(:blood_pressure, facility: facility, patient: patient, recorded_at: 2.months.ago, user: user_2)
      create(:blood_pressure, facility: facility, patient: patient, recorded_at: 2.months.ago, user: user_2)
      expected = {
        Period.month("January 2021") => {user_1.id => 1, user_2.id => 0},
        Period.month("February 2021") => {user_1.id => 0, user_2.id => 0},
        Period.month("March 2021") => {user_1.id => 0, user_2.id => 2}

      }
      expect(described_class.new.count(facility, :month, group_by: :user_id)).to eq(expected)
    end
  end
end
