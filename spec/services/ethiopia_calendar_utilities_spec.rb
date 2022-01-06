# frozen_string_literal: true

require "rails_helper"

RSpec.describe EthiopiaCalendarUtilities do
  describe ".ethiopian_to_gregorian" do
    it "converts Ethiopian calendar dates to Gregorian calendar dates" do
      conversions = {
        [2013, 4, 30] => "2021-01-08",
        [2013, 5, 14] => "2021-01-22",
        [2013, 5, 16] => "2021-01-24",
        [2013, 7, 16] => "2021-03-25",
        [2013, 8, 20] => "2021-04-28",
        [2013, 9, 9] => "2021-05-17",
        [2012, 10, 5] => "2020-06-12",
        [2013, 11, 6] => "2021-07-13",
        [2013, 11, 8] => "2021-07-15",
        [2013, 11, 28] => "2021-08-04"
      }

      conversions.each do |ethiopia_date, gregorian_date|
        converted_date = described_class.ethiopian_to_gregorian(*ethiopia_date)

        expect(converted_date.strftime("%Y-%m-%d")).to eq(gregorian_date)
      end
    end
  end

  describe ".gregorian_month_period_to_ethiopian" do
    it "converts Gregorian monthly periods to Ethiopian monthly periods" do
      conversions = {
        [2021, 1, 1] => "2013-05",
        [2021, 2, 1] => "2013-06",
        [2021, 3, 1] => "2013-07",
        [2021, 4, 1] => "2013-08",
        [2021, 5, 1] => "2013-09",
        [2021, 6, 1] => "2013-10",
        [2021, 7, 1] => "2013-11",
        [2021, 8, 1] => "2013-12",
        [2021, 9, 1] => "2014-01",
        [2021, 10, 1] => "2014-02",
        [2021, 11, 1] => "2014-03",
        [2021, 12, 1] => "2014-04",
        [2022, 1, 1] => "2014-05"
      }

      conversions.each do |gregorian_month, ethiopian_month|
        period = Period.month(Date.new(*gregorian_month))
        converted_period = described_class.gregorian_month_period_to_ethiopian(period)

        expect(converted_period.to_date.strftime("%Y-%m")).to eq(ethiopian_month)
      end
    end
  end
end
