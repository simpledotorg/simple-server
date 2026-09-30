require "rails_helper"

RSpec.describe DrRai::StatinsIndicator, type: :model do
  let(:district_with_facilities) { setup_district_with_facilities }
  let(:region) { district_with_facilities[:region] }
  let(:indicator) { DrRai::StatinsIndicator.new }

  describe "#is_supported?" do
    context "when region has data" do
      before do
        allow(indicator).to receive(:datasource).with(region).and_return({"some" => "data"})
      end

      it "works" do
        expect(indicator.is_supported?(region)).to be_truthy
      end
    end

    context "when region has no data" do
      before do
        allow(indicator).to receive(:datasource).with(region).and_return({})
      end

      it "is unsupported" do
        expect(indicator.is_supported?(region)).to be_falsey
      end
    end
  end

  describe "#numerator and #denominator" do
    let(:quarter) { Period.quarter(Date.new(2025, 4, 1)) }

    before do
      allow(indicator).to receive(:datasource).with(region).and_return(
        quarter => {
          "adjusted_dm_patients_40_and_above_with_statins" => 14,
          "adjusted_dm_patients_40_and_above_under_care" => 120
        }
      )
    end

    it "reads the DM patients ≥40y prescribed statins from the facility states" do
      expect(indicator.numerator(region, quarter)).to eq 14
    end

    it "reads the DM patients ≥40y under care from the facility states" do
      expect(indicator.denominator(region, quarter)).to eq 120
    end
  end

  describe "quarterly aggregation" do
    let(:monthly_data) do
      # Mar to Sep 2026: [with statins, under care]
      {[2026, 3] => [2, 37], [2026, 4] => [5, 45], [2026, 5] => [9, 53], [2026, 6] => [13, 61],
       [2026, 7] => [18, 69], [2026, 8] => [23, 63], [2026, 9] => [27, 48]}.map do |(year, month), (statins, under_care)|
        [Period.month(Date.new(year, month, 1)), {
          "adjusted_dm_patients_40_and_above_with_statins" => statins,
          "adjusted_dm_patients_40_and_above_under_care" => under_care
        }]
      end.to_h
    end

    before do
      allow(Reports::RegionSummary).to receive(:call).and_return(region.slug => monthly_data)
    end

    it "uses the last month of the quarter" do
      expect(indicator.quarterly_aggregation).to eq :eoq
    end

    it "reports the last month of each quarter instead of the sum" do
      q2 = Period.quarter(Date.new(2026, 4, 1))
      q3 = Period.quarter(Date.new(2026, 7, 1))

      expect(indicator.numerator(region, q2)).to eq 13
      expect(indicator.denominator(region, q2)).to eq 61
      expect(indicator.numerator(region, q3)).to eq 27
      expect(indicator.denominator(region, q3)).to eq 48
    end
  end
end
