require "rails_helper"

RSpec.describe Reports::Percentage, type: :helper do
  describe "#percentage" do
    context "when with_rounding is true" do
      it "returns percentage after rounding to zero precision" do
        expect(percentage(1, 3, with_rounding: true)).to eq(33)
      end
    end

    context "when with_rounding is not provided" do
      it "defaults to true" do
        expect(percentage(1, 3)).to eq(33)
      end
    end

    context "when with_rounding is false" do
      it "returns percentage without rounding" do
        expect(percentage(1, 3, with_rounding: false)).to eq(33.33333333333333)
      end
    end

    it "returns zero when numerator or denominator is nil" do
      expect(percentage(nil, 3, with_rounding: false)).to eq(0)
      expect(percentage(1, nil, with_rounding: false)).to eq(0)
    end

    it "returns zero when numerator or denominator is zero" do
      expect(percentage(0, 3, with_rounding: false)).to eq(0)
      expect(percentage(1, 0, with_rounding: false)).to eq(0)
    end
  end

  describe "#rounded_percentages" do
    context "when given a hash of counts without rounding" do
      it "calculates percentages" do
        expect(rounded_percentages({a: 0, b: 800, c: 200})).to eq({a: 0, b: 80, c: 20})
      end

      it "rounds percentages so that they add up to 100" do
        expect(rounded_percentages({a: 0, b: 6.501707128047701, c: 80.72721472499585, d: 10.985525877598509, e: 1.7855522693579489})).to eq({a: 0, b: 6, c: 81, d: 11, e: 2})
        expect(rounded_percentages({a: 37.125748502994014, b: 20.958083832335326, c: 19.161676646706585, d: 22.75449101796407})).to eq({a: 37, b: 21, c: 19, d: 23})
      end

      it "doesn't guarantee which percentage is rounded when equal elements are present" do
        expect(rounded_percentages({a: 33.333, b: 33.333, c: 33.333}).values).to match_array [34, 33, 33]
        expect(rounded_percentages({a: 42.857, b: 28.571, c: 28.571})).to include(a: 43)
        expect(rounded_percentages({a: 42.857, b: 28.571, c: 28.571}).values).to include(28, 29)
      end

      it "returns zeroes when the counts are all zeroes" do
        expect(rounded_percentages({a: 0, b: 0, c: 0})).to eq({a: 0, b: 0, c: 0})
      end
    end
  end
end
