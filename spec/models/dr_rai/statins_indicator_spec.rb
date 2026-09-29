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
end
