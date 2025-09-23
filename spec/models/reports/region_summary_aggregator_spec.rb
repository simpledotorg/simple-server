require "rails_helper"

RSpec.describe Reports::RegionSummaryAggregator do
  let(:start_date) { Date.parse("2021-01-01") }
  let(:data) do
    # This gives the data
    # | J | F | M | A | M | J | J | A | S | O  | N  | D  |
    # | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
    # for year 2021
    result = Hash.new(0)
    12.times do |advance|
      the_month = start_date >> advance
      the_period = the_month.to_period
      result[the_period] = {
        "test_attribute" => advance + 1
      }
    end
    {
      "test_region" => result
    }
  end

  describe "#well_formed?" do
    it "ensures the data is in the required fromat" do
      expect(described_class.new(data)).to be_well_formed
    end
  end

  describe "#monthly" do
    it "makes no change to the data" do
      expect(described_class.new(data).monthly).to eq(data)
    end
  end

  describe "quarterly" do
    context ":sum" do
      it "sums the data for each month in the quarter" do
        aggregate = described_class.new(data).quarterly(with: :sum)
        values = aggregate["test_region"]
          .map { |_, v| v.map { |_, q| q } }
          .flatten
        expect(values).to match_array([6, 15, 24, 33])
      end
    end

    context ":eoq" do
      it "uses the last available month entry as the quarter value" do
        aggregate = described_class.new(data).quarterly(with: :eoq)
        values = aggregate["test_region"]
          .map { |_, v| v.map { |_, q| q } }
          .flatten
        expect(values).to match_array([3, 6, 9, 12])
      end
    end

    context ":rollup" do
      it "compounds the data for each month into the quarter value" do
        aggregate = described_class.new(data).quarterly(with: :rollup)
        values = aggregate["test_region"]
          .map { |_, v| v.map { |_, q| q } }
          .flatten
        expect(values).to match_array([6, 21, 45, 78])
      end
    end
  end
end
