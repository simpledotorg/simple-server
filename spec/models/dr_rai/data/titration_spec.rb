require "rails_helper"

RSpec.describe DrRai::Data::Titration, type: :model do
  context "data transformations" do
    # from
    # month_date, facility_name, follow_up_count, titrated_count, titration_rate
    # May 1 2025, Some Hospital, 120, 14, 11.67
    # to
    # {
    #   "Some Hospital": {
    #     <Period value: "Q2-2025">: {
    #       follow_up_count: 120,
    #       titrated_count: 14,
    #       titration_rate: 106,
    #     }
    #   }
    # }
    it "has two internal keys" do
      expect(described_class.instance_variable_get(:@chartable_internal_keys).count).to eq 2
      expect(described_class.instance_variable_get(:@chartable_internal_keys)).to match(%i[follow_up_count titrated_count])
    end

    it "uses month_date as period key" do
      expect(described_class.instance_variable_get(:@chartable_period_key)).to eq :month_date
    end

    it "uses facility_name as outer_grouping" do
      expect(described_class.instance_variable_get(:@chartable_outer_grouping)).to eq :facility_name
    end
  end
end
