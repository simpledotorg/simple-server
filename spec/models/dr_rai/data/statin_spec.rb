require 'rails_helper'

RSpec.describe DrRai::Data::Statin, type: :model do
  context "data transformations" do
    # from
    # month_date, aggregate_root, eligible_patients, patients_prescribed_statins, percentage_statin
    # May 1 2025, Some Hospital, 120, 14, 11.67
    # to
    # {
    #   "Some Hospital": {
    #     <Period value: "Q2-2025">: {
    #       follow_up_count: 120,
    #       titrated_count: 14,
    #     }
    #   }
    # }
    it "has two internal keys" do
      expect(described_class.instance_variable_get(:@chartable_internal_keys).count).to eq 2
      expect(described_class.instance_variable_get(:@chartable_internal_keys)).to match(%i[eligible_patients patients_prescribed_statins])
    end

    it "uses month_date as period key" do
      expect(described_class.instance_variable_get(:@chartable_period_key)).to eq :month_date
    end

    it "uses facility_name as outer_grouping" do
      expect(described_class.instance_variable_get(:@chartable_outer_grouping)).to eq :facility_name
    end
  end
end
