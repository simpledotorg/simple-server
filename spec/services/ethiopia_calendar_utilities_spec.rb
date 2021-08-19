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
end
