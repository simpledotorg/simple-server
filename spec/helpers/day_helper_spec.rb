# frozen_string_literal: true

require "rails_helper"

RSpec.describe DayHelper, type: :helper do
  describe "#doy_to_date" do
    it "turns year and day to a date" do
      expect(doy_to_date(2018, 2)).to eq(Date.new(2018, 1, 2))
    end

    it "respects strings as input as well" do
      expect(doy_to_date("2019", "5")).to eq(Date.new(2019, 1, 5))
    end
  end
end
