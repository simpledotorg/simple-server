require "rails_helper"

RSpec.describe Period, type: :model do
  let(:jan_1_2019) { Time.parse("January 1st, 2019") }
  let(:jan_1_2020) { Time.parse("January 1st, 2020") }
  let(:may_8_2020) { Time.parse("May 8th, 2020") }
  let(:jan_1_2019_month_period) { Period.month(jan_1_2019) }
  let(:jan_1_2020_month_period) { Period.month(jan_1_2020) }
  let(:may_8_2020_month_period) { Period.month(may_8_2020) }

  let(:quarter_1_2019) { Quarter.new(date: jan_1_2019) }
  let(:quarter_1_2020) { Quarter.new(date: jan_1_2020) }
  let(:quarter_2_2020) { Quarter.new(date: may_8_2020) }
  let(:q1_2019_period) { Period.quarter(quarter_1_2019) }
  let(:q1_2020_period) { Period.quarter(quarter_1_2020) }
  let(:q2_2020_period) { Period.quarter(quarter_2_2020) }

  it "times and dates can convert themselves into periods" do
    expect(jan_1_2019.to_period).to eq(Date.parse("January 1st 2019").to_period)
    expect(jan_1_2019.to_period.value).to eq(Date.parse("January 1st 2019").to_period.value)
  end

  it "has validations" do
    period = Period.new(type: "invalid", value: jan_1_2020)
    expect(period).to be_invalid
    expect(period.errors[:type]).to eq(["must be month or quarter"])
    period.type = :month
    expect(period).to be_valid
  end

  it "has to_s in correct format" do
    expect(jan_1_2019_month_period.to_s).to eq("Jan 2019")
    expect(q1_2019_period.to_s).to eq("Q1-2019")
  end

  it "period months can be compared" do
    expect(jan_1_2020_month_period).to be > jan_1_2019_month_period
    expect(jan_1_2019_month_period).to be < jan_1_2020_month_period
  end

  it "period quarters can be compared" do
    expect(q1_2019_period).to be < q1_2020_period
    expect(q1_2020_period).to be > q1_2019_period
  end

  it "cannot compare period with other classes" do
    expect {
      q1_2019_period > jan_1_2019
    }.to raise_error(ArgumentError, "you are trying to compare a Time with a Period")
  end

  it "cannot compare month and quarter periods" do
    expect {
      q1_2019_period > jan_1_2019_month_period
    }.to raise_error(ArgumentError, "can only compare Periods of the same type")
  end

  it "can be advanced forward and backwards" do
    expect(jan_1_2019_month_period.advance(months: 1)).to eq(Period.month(Date.parse("February 1 2019")))
    expect(jan_1_2019_month_period.advance(years: 1)).to eq(jan_1_2020_month_period)
    expect(q1_2019_period.advance(years: 1)).to eq(q1_2020_period)
    q2_2019_period = Period.quarter("Q2-2019")
    expect(q1_2019_period.advance(months: 3)).to eq(q2_2019_period)
  end

  it "can return its blood pressure control range" do
    range = jan_1_2020_month_period.blood_pressure_control_range
    expect(range.begin).to eq(Date.parse("October 31st 2019"))
    expect(range.end).to eq(Date.parse("January 31st 2020"))

    range = Period.month("July 1st 2020").blood_pressure_control_range
    expect(range.begin).to eq(Date.parse("April 30th 2020"))
    expect(range.end).to eq(Date.parse("July 31st 2020"))
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

  it "months provide start and end dates" do
    expect(may_8_2020_month_period.start_date).to eq(Date.parse("May 1st, 2020"))
    expect(may_8_2020_month_period.end_date).to eq(Date.parse("May 31st, 2020"))
  end

  it "quarters provide start and end dates" do
    expect(q2_2020_period.start_date).to eq(Date.parse("April 1st, 2020"))
    expect(q2_2020_period.end_date).to eq(Date.parse("June 30, 2020"))
  end
end
