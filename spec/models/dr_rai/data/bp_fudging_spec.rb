require "rails_helper"

RSpec.describe DrRai::Data::BpFudging, type: :model do
  context "data transformations" do
    # from
    # quarter, slug, numerator, denominator, ratio
    # Q1-2025, Some Hospital, 120, 14, 0.67
    # to
    # {
    #   "Some Hospital": {
    #     <Period value: "Q2-2025">: {
    #       numerator: 120,
    #       denominator: 14,
    #       ratio: 0.67,
    #     }
    #   }
    # }
    it "has three internal keys" do
      expect(described_class.instance_variable_get(:@chartable_internal_keys).count).to eq 3
      expect(described_class.instance_variable_get(:@chartable_internal_keys)).to match(%i[numerator denominator ratio])
    end

    it "uses quarter as period key" do
      expect(described_class.instance_variable_get(:@chartable_period_key)).to eq :quarter
    end

    it "uses slug as outer_grouping" do
      expect(described_class.instance_variable_get(:@chartable_outer_grouping)).to eq :slug
    end
  end
end
