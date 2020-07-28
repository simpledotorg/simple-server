require "rails_helper"

RSpec.describe Period, type: :model do
  let(:jan_1_2019) { Time.parse("January 1st, 2019") }
  let(:jan_1_2020) { Time.parse("January 1st, 2020") }

  let(:quarter_1_2019) { Quarter.new(date: jan_1_2019) }
  let(:quarter_1_2020) { Quarter.new(date: jan_1_2020) }

  it "validations" do
    period = Period.new(type: "invalid", value: jan_1_2020)
    expect(period).to be_invalid
    expect(period.errors[:type]).to eq(["must be month or quarter"])
    period.type = :month
    expect(period).to be_valid
  end

  it "period months can be compared" do
    expect(Period.month(jan_1_2020)).to be > Period.month(jan_1_2019)
    expect(Period.month(jan_1_2019)).to be < Period.month(jan_1_2020)
    expect(jan_1_2020).to eq(Time.parse("January 1st, 2020"))
  end

  it "period quarters can be compared" do
    expect(Period.quarter(quarter_1_2019)).to be < Period.quarter(quarter_1_2020)
    expect(Period.quarter(quarter_1_2020)).to be > Period.quarter(quarter_1_2019)
  end

  it "can be used in ranges" do
    range = (Period.quarter(quarter_1_2019)..Period.quarter(quarter_1_2020))
    expect(range.entries.size).to eq(5)
  end

  it "creating from date for quarter" do
    period = Period.quarter(jan_1_2020)
    expect(period).to eq(Period.quarter(quarter_1_2020))
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

  it "creates Quarter if initialized with quarter string" do
    quarter_1_2020 = Quarter.new(date: jan_1_2020)
    period = Period.quarter("Q1-2020")
    expect(period.value).to be_instance_of(Quarter)
    expect(period.value).to eq(quarter_1_2020)
  end
end