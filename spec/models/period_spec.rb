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

  shared_examples_for "ActiveModel" do
    include ActiveModel::Lint::Tests

    before do
      @model = active_model_instance
    end

    ActiveModel::Lint::Tests.public_instance_methods.map { |method| method.to_s }.grep(/^test/).each do |method|
      example(method.tr("_", " ")) { send method }
    end
  end

  let(:active_model_instance) { Period.new(type: "month", value: jan_1_2020) }

  it_behaves_like "ActiveModel"

  context "creation" do
    it "can be created from a quarter string in attributes" do
      period = Period.new(type: "quarter", value: "Q1-2020")
      expect(period.value).to be_instance_of(Quarter)
      expect(period.value).to eq(quarter_1_2020)
    end

    it "can be created from a date String" do
      period = Period.new(type: "month", value: "2020-04-01")
      expect(period.value).to be_instance_of(Date)
      expect(period.value).to eq(Date.parse("2020-04-01"))
    end

    it "quarters can be created with a Quarter object" do
      quarter_1_2020 = Quarter.new(date: jan_1_2020)
      period = Period.new(type: :quarter, value: "Q1-2020")
      expect(period.value).to be_instance_of(Quarter)
      expect(period.value).to eq(quarter_1_2020)
    end

    it "quarters can be created with a month Date" do
      period = Period.new(type: :quarter, value: jan_1_2020)
      expect(period.value).to be_instance_of(Quarter)
      expect(period).to eq(Period.quarter(quarter_1_2020))
    end

    it "coerces month dates to the beginning of the month" do
      date = Date.parse("December 12, 2020")
      period = Period.new(type: :month, value: date)
      expect(period.value).to eq(Date.parse("December 1, 2020"))
    end
  end

  context "display dates" do
    it "knows the registration end date" do
      expect(jan_1_2019.to_period.bp_control_registrations_until_date).to eq("31-Oct-2018")
    end

    it "can display the begin / end range of the BP control range" do
      expect(jan_1_2019.to_period.bp_control_range_start_date).to eq("1-Nov-2018")
      expect(jan_1_2019.to_period.bp_control_range_end_date).to eq("31-Jan-2019")
    end
  end

  it "times and dates can convert themselves into periods" do
    expect(jan_1_2019.to_period).to eq(Date.parse("January 1st 2019").to_period)
    expect(jan_1_2019.to_period.value).to eq(Date.parse("January 1st 2019").to_period.value)
  end

  it "has validations" do
    expect { Period.new(type: "invalid", value: jan_1_2020) }.to raise_error(ActiveModel::ValidationError)
    period = Period.new(value: jan_1_2019, type: :month)
    expect(period).to be_valid
  end

  it "has to_s in correct default format" do
    expect(jan_1_2019_month_period.to_s).to eq("Jan-2019")
    expect(q1_2019_period.to_s).to eq("Q1-2019")
  end

  it "has to_dhis2 in correct format" do
    expect(jan_1_2019_month_period.to_s(:dhis2)).to eq("201901")
    expect(q1_2019_period.to_s(:dhis2)).to eq("2019Q1")
  end

  it "periods take an optional arg for to_s formatting" do
    expect(jan_1_2019_month_period.to_s(:mon_year_multiline)).to eq("Jan\n2019")
    expect(q1_2019_period.to_s(:dhis2)).to eq("2019Q1")
  end

  it "prints default format for unknown format strings" do
    expect(jan_1_2019_month_period.to_s(:unknown)).to eq("2019-01-01")
    expect(q1_2019_period.to_s(:unknown)).to eq("Q1-2019")
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

  it "month and quarter periods are never equal" do
    expect(q1_2019_period).to_not eq(jan_1_2019_month_period)
  end

  it "month and quarter periods are not comparable" do
    # this exception comes from Ruby (via Comparable), so we can't easily override it to be more descriptive
    expect {
      q1_2019_period < jan_1_2019_month_period
    }.to raise_error(ArgumentError, "comparison of Period with Period failed")
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
    expect(range.begin).to eq(Date.parse("November 1st 2019").beginning_of_day)
    expect(range.end).to eq(Date.parse("January 31st 2020").end_of_day)

    range = Period.month("July 1st 2020").blood_pressure_control_range
    expect(range.begin).to eq(Date.parse("May 1st 2020").beginning_of_day)
    expect(range.end).to eq(Date.parse("July 31st 2020").end_of_day)

    range = Period.month("February 1st 2020").blood_pressure_control_range
    expect(range.begin).to eq(Date.parse("December 1st 2019").beginning_of_day)
    expect(range.end).to eq(Date.parse("February 29th 2020").end_of_day)
  end

  it "can be used in ranges" do
    range = (Period.quarter(quarter_1_2019)..Period.quarter(quarter_1_2020))
    expect(range.entries.size).to eq(5)
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

  it "months provide begin and end" do
    expect(may_8_2020_month_period.begin).to eq(Time.zone.parse("May 1st, 2020").beginning_of_day)
    expect(may_8_2020_month_period.end).to eq(Time.zone.parse("May 31st, 2020").end_of_day)
  end

  it "quarters provide start and end" do
    expect(q2_2020_period.begin).to eq(Date.parse("April 1st, 2020").beginning_of_day)
    expect(q2_2020_period.end).to eq(Date.parse("June 30, 2020").end_of_day)
  end

  it "has adjective description" do
    expect(jan_1_2019_month_period.adjective).to eq("Monthly")
    expect(q2_2020_period.adjective).to eq("Quarterly")
  end

  describe "quarter?" do
    it "returns true when period is a quarter, false when it's a not" do
      period = Period.quarter(Date.parse("December 2019"))
      expect(period.quarter?).to eq true
      period = Period.month(Date.parse("December 2019"))
      expect(period.quarter?).to eq false
    end
  end

  describe "month?" do
    it "returns true when period is month, false when it's not" do
      period = Period.month(Date.parse("December 2019"))
      expect(period.month?).to eq true
      period = Period.quarter(Date.parse("December 2019"))
      expect(period.month?).to eq false
    end
  end
end
