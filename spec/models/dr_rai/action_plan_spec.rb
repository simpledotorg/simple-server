require "rails_helper"

RSpec.describe DrRai::ActionPlan, type: :model do
  describe "#denominator" do
    context "for numeric targets" do
      let(:indicator) { DrRai::ContactOverduePatientsIndicator.create }
      let(:target) { DrRai::NumericTarget.create(numeric_value: 20, period: "Q1-2025") }
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

  describe "#goal_statement" do
    let(:indicator) { DrRai::ContactOverduePatientsIndicator.create }
    let(:district_with_facilities) { setup_district_with_facilities }
    let(:region) { district_with_facilities[:region] }

    def action_plan_for(target)
      DrRai::ActionPlan.new(dr_rai_target: target,
        dr_rai_indicator: indicator,
        region: region,
        statement: "TODO")
    end

    context "for percentage targets with a goal" do
      let(:target) { DrRai::PercentageTarget.create(numeric_value: 20, percentage_value: 35, period: "Q1-2025") }

      it "describes the goal using the indicator's unit and passive action" do
        expect(action_plan_for(target).goal_statement).to eq "Goal: 35% of overdue patients called"
      end
    end

    context "for percentage targets without a goal" do
      let(:target) { DrRai::PercentageTarget.create(numeric_value: 20, period: "Q1-2025") }

      it "should be nil" do
        expect(action_plan_for(target).goal_statement).to be_nil
      end
    end

    context "for non-percentage targets" do
      let(:target) { DrRai::NumericTarget.create(numeric_value: 20, period: "Q1-2025") }

      it "should be nil" do
        expect(action_plan_for(target).goal_statement).to be_nil
      end
    end
  end

  describe "#progress" do
    let(:indicator) { DrRai::ContactOverduePatientsIndicator.create }
    let(:target) { DrRai::NumericTarget.create(numeric_value: 20, period: "Q1-2025") }
    let(:district_with_facilities) { setup_district_with_facilities }
    let(:region) { district_with_facilities[:region] }

    before do
      allow_any_instance_of(DrRai::ContactOverduePatientsIndicator).to receive(:numerator).with(anything, anything).and_return(9)
    end

    it "calculates pecentage to 2 decimal places" do
      action_plan = DrRai::ActionPlan.new(dr_rai_target: target,
        dr_rai_indicator: indicator,
        region: region,
        statement: "TODO")
      expect(action_plan.progress).to eq((9.to_f / 20 * 100))
    end
  end
end
