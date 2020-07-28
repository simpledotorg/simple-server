require "rails_helper"

RSpec.describe Period, type: :model do
  let(:jan_1_2019) { Time.parse("January 1st, 2019") }
  let(:jan_1_2020) { Time.parse("January 1st, 2020") }

  it "validations" do
    period = Period.new(type: "invalid", value: jan_1_2020)
    expect(period).to be_invalid
    expect(period.errors[:type]).to eq(["must be month or quarter"])
    period.type = :month
    expect(period).to be_valid
  end

  it "months can be compared" do
    expect(jan_1_2020).to be > jan_1_2019
    expect(jan_1_2019).to be < jan_1_2020
    expect(jan_1_2020).to eq(Time.parse("January 1st, 2020"))
  end

  it "quarters can be compared" do
    quarter_1_2019 = Quarter.new(date: jan_1_2019)
    quarter_1_2020 = Quarter.new(date: jan_1_2020)
    expect(quarter_1_2019).to be < quarter_1_2020
    expect(quarter_1_2020).to be > quarter_1_2019
  end

  it "same quarters are equal and have same hash code" do
    q1_01 = Quarter.new(date: Time.parse("January 1st, 2020"))
    q1_02 = Quarter.new(date: Time.parse("March 1st, 2020"))
    q2 = Quarter.new(date: Time.parse("April 1st, 2020"))
    expect(q1_01).to eq(q1_02)
    expect(q1_01.hash).to eq(q1_02.hash)
    expect(q1_01).to_not eq(q2)
    expect(q1_01.hash).to_not eq(q2.hash)
  end
end