# frozen_string_literal: true

require "rails_helper"

RSpec.describe PeriodHelper, type: :helper do
  include MonthHelper
  include DayHelper
  include QuarterHelper

  describe "#period_list_as_dates" do
    let(:current_date) { Date.current }

    it "generates a sorted list of dates given a quarter and time range" do
      expect(period_list_as_dates(:quarter, 3)).to eq([current_date.beginning_of_quarter,
        current_date.beginning_of_quarter - 3.months,
        current_date.beginning_of_quarter - 6.months])
    end

    it "generates a sorted list of dates given a month and time range" do
      expect(period_list_as_dates(:month, 3)).to eq([current_date.beginning_of_month,
        current_date.beginning_of_month - 1.month,
        current_date.beginning_of_month - 2.months])
    end

    it "generates a sorted list of dates given a day and time range" do
      expect(period_list_as_dates(:day, 3)).to eq([current_date,
        current_date - 1.day,
        current_date - 2.days])
    end

    it "returns nil if period is unsupported" do
      expect(period_list_as_dates(:week, 3)).to be_nil
    end
  end
end
