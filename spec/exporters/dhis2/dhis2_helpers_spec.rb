require "rails_helper"

describe Dhis2::Helpers do
  describe "#reporting_period" do
    it "should format month_date to DHIS2 format by the Ethiopian calendar if Flipper flag is enabled" do
      Flipper.enable(:dhis2_use_ethiopian_calendar)
      month_date = Period.current
      expected_month_date = EthiopiaCalendarUtilities.gregorian_month_period_to_ethiopian(month_date).to_s(:dhis2)
      expect(described_class.reporting_period(month_date)).to eq(expected_month_date)
    end

    it "should format month_date to DHIS2 format by the Gregorian calendar if Flipper flag is disabled" do
      Flipper.disable(:dhis2_use_ethiopian_calendar)
      month_date = Period.current
      expected_month_date = month_date.to_s(:dhis2)
      expect(described_class.reporting_period(month_date)).to eq(expected_month_date)
    end
  end
end
