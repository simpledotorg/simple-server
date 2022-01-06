# frozen_string_literal: true

require "rails_helper"

RSpec.describe MonthHelper, type: :helper do
  describe "#moy_to_date" do
    it "turns year and month to a date" do
      expect(moy_to_date(2018, 2)).to eq(Date.new(2018, 2, 1))
    end

    it "respects strings as input as well" do
      expect(moy_to_date("2019", "3")).to eq(Date.new(2019, 3, 1))
    end
  end
end
