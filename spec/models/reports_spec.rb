require "rails_helper"

RSpec.describe Reports do
  context ".default_period" do
    it "is the current month in the reporting time zone" do
      Timecop.freeze("June 1st 2020 00:00 AM IST") do
        expect(described_class.default_period).to eq(Period.month("June 30 2020"))
      end
      Timecop.freeze("May 31st 2020 20:00 EST") do
        expect(described_class.default_period).to eq(Period.month("June 30 2020"))
      end
    end
  end
end
