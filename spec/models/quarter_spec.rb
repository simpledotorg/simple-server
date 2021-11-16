require "rails_helper"

RSpec.describe Quarter, type: :model do
  let(:jan_1) { Time.parse("January 1st, 2020 00:00:00+00:00") }
  let(:jan_1_date) { Date.parse("January 1st, 2020") }

  let(:q1_2019) { Quarter.new(date: Time.parse("January 1st, 2019")) }
  let(:q1_2020) { Quarter.new(date: Time.parse("January 1st, 2020")) }
  let(:q3_2020) { Quarter.new(date: Time.parse("August 1st, 2020")) }

  context "parse" do
    it "can parse" do
      quarter = Quarter.parse("Q2-2020")
      expect(quarter.number).to eq(2)
      expect(quarter.year).to eq(2020)
    end

    it "will handle a string Date" do
      quarter = Quarter.parse("2020-08-01")
      expect(quarter.number).to eq(3)
      expect(quarter.year).to eq(2020)
      expect(quarter.date).to eq(Date.parse("2020-08-01"))
      expect(quarter.to_s).to eq("Q3-2020")
    end
  end

  it "raises for bad string parsing" do
    expect {
      Quarter.parse("Qx-2020")
    }.to raise_error(ArgumentError)
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

  it "can be compared" do
    expect(q1_2019).to be < q1_2020
    expect(q1_2020).to be < q3_2020
    expect(q3_2020).to be > q1_2020
  end

  it "normalizes non-Dates into Dates when created" do
    time = Time.parse("January 1st, 2020")
    quarter = Quarter.new(date: time)
    expect(quarter.date).to be_instance_of(Date)
    expect(quarter.date).to eq(jan_1_date)
    datetime = DateTime.parse("January 1st 2020 00:00:00+00:00")
    quarter = Quarter.new(date: datetime)
    expect(quarter.date).to be_instance_of(Date)
    expect(quarter.date).to eq(jan_1_date)
  end

  it "can create from date" do
    time = Time.parse("January 1st, 2020")
    quarter = Quarter.new(date: time)
    expect(quarter.number).to eq(1)
    expect(quarter.year).to eq(2020)
    expect(quarter.date).to eq(time.to_date)
    expect(quarter.to_s).to eq("Q1-2020")
  end

  it "has quarter_string specific db format" do
    expect(q1_2019.to_s(:quarter_string)).to eq("2019-1")
    expect(q3_2020.to_s(:quarter_string)).to eq("2020-3")
  end

  it "can return previous and next quarter" do
    date = Time.parse("January 1st, 2020")
    quarter = Quarter.new(date: date)
    next_quarter = quarter.next_quarter
    expect(next_quarter.number).to eq(2)
    expect(next_quarter.year).to eq(2020)
    previous_quarter = quarter.previous_quarter
    expect(previous_quarter.number).to eq(4)
    expect(previous_quarter.year).to eq(2019)
  end

  it "can return the current Quarter" do
    Timecop.freeze(jan_1) do
      quarter = Quarter.current
      expect(quarter.number).to eq(1)
      expect(quarter.year).to eq(2020)
    end
  end

  it "can return an enumerable collection of previous or next quarters" do
    Timecop.freeze(jan_1) do
      expected_quarters = [1, 4, 3, 2]
      expected_years = [2020, 2019, 2019, 2019]
      Quarter.current.downto(3).each_with_index do |quarter, index|
        expect(quarter.number).to eq(expected_quarters[index])
        expect(quarter.year).to eq(expected_years[index])
      end

      expected_quarters = [1, 2, 3, 4, 1]
      expected_years = [2020, 2020, 2020, 2020, 2021]
      Quarter.current.upto(4).each_with_index do |quarter, index|
        expect(quarter.number).to eq(expected_quarters[index])
        expect(quarter.year).to eq(expected_years[index])
      end
    end
  end

  it "can return its begin and end times" do
    date = Time.parse("May 21st, 2020")
    quarter = Quarter.new(date: date)
    expect(quarter.begin).to eq(Date.parse("April 1, 2020").beginning_of_day)
    expect(quarter.end).to eq(Date.parse("June 30, 2020").end_of_day)
  end
end
