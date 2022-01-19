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

  describe "#rounded_percentages" do
    it "returns hash of percentages after rounding when given a hash of percentages without rounding" do
      expect(rounded_percentages({a: 0, b: 0, c: 0})).to eq({a: 0, b: 0, c: 0})
      expect(rounded_percentages({a: 0, b: 80, c: 20})).to eq({a: 0, b: 80, c: 20})
      expect(rounded_percentages({a: 33.333, b: 33.333, c: 33.333})).to eq({a: 34, b: 33, c: 33})
      expect(rounded_percentages({a: 42.857, b: 28.571, c: 28.571})).to eq({a: 43, b: 29, c: 28})
      expect(rounded_percentages({a: 0, b: 6.501707128047701, c: 80.72721472499585, d: 10.985525877598509, e: 1.7855522693579489})).to eq({a: 0, b: 6, c: 81, d: 11, e: 2})
      expect(rounded_percentages({a: 18.562874251497007, b: 20.958083832335326, c: 18.562874251497007, d: 19.161676646706585, e: 22.75449101796407})).to eq({a: 19, b: 21, c: 18, d: 19, e: 23})
    end
  end
end
