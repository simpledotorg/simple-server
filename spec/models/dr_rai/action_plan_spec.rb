require "rails_helper"

RSpec.describe DrRai::ActionPlan, type: :model do
  describe "#denominator" do
    context "for numeric targets" do
      let(:indicator) { DrRai::ContactOverduePatientsIndicator.create }
      let(:target) { DrRai::NumericTarget.create(indicator: indicator, numeric_value: 20) }
      let(:district_with_facilities) { setup_district_with_facilities }
      let(:region) { district_with_facilities[:region] }

      it "should be the numeric_value" do
        action_plan = DrRai::ActionPlan.new(dr_rai_target: target,
          dr_rai_indicator: indicator,
          region: region,
          statement: "TODO")
        expect(action_plan.denominator).to eq 20
      end
    end
  end
end
