# frozen_string_literal: true

require "rails_helper"

RSpec.describe DashboardHelper, type: :helper do
  let(:first_jan) { Date.new(2019, 1, 1) }
  let(:first_feb) { Date.new(2019, 2, 1) }
  let(:first_mar) { Date.new(2019, 3, 1) }
  let(:first_apr) { Date.new(2019, 4, 1) }
  let(:first_jul) { Date.new(2019, 7, 1) }

  describe "#dates_for_periods" do
    context "month" do
      it "returns the last n months starting from the beginning" do
        expected_months = []

        Timecop.travel(first_apr) do
          expected_months = dates_for_periods(:month, 3)
        end

        expect(expected_months).to eq([first_jan, first_feb, first_mar])
      end
    end

    context "quarter" do
      it "returns the last n quarters starting from the beginning" do
        expected_months = dates_for_periods(:quarter, 2, from_time: first_jul)

        expect(expected_months).to eq([first_jan, first_apr])
      end
    end

    context "number_or_dash_with_delimiter" do
      it "returns dash if number is zero-ish" do
        expect(number_or_dash_with_delimiter(0)).to eq("-")
        expect(number_or_dash_with_delimiter(nil)).to eq("-")
        expect(number_or_dash_with_delimiter("")).to eq("-")
      end

      it "returns number with delimter with a valid number" do
        expect(number_or_dash_with_delimiter(12335)).to eq("12,335")
        expect(number_or_dash_with_delimiter(12335, delimiter: "_")).to eq("12_335")
        expect(number_or_dash_with_delimiter(100)).to eq("100")
      end
    end
  end
end
