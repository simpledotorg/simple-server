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

  describe "#progress for an indicator with goals relative to the previous quarter" do
    let(:indicator) { DrRai::StatinsIndicator.create }
    let(:district_with_facilities) { setup_district_with_facilities }
    let(:region) { district_with_facilities[:region] }
    let(:q3) { Period.quarter(Date.new(2026, 7, 1)) }
    let(:q4) { Period.quarter(Date.new(2026, 10, 1)) }

    def action_plan_with(target_value:, previous:, current:)
      allow_any_instance_of(DrRai::StatinsIndicator).to receive(:numerator).with(anything, q3).and_return(previous)
      allow_any_instance_of(DrRai::StatinsIndicator).to receive(:numerator).with(anything, q4).and_return(current)
      target = DrRai::PercentageTarget.create(numeric_value: target_value, period: q4.value.to_s)
      DrRai::ActionPlan.new(dr_rai_target: target, dr_rai_indicator: indicator, region: region, statement: "TODO")
    end

    it "measures the change since the previous quarter against the target" do
      action_plan = action_plan_with(target_value: 7, previous: 27, current: 31)
      expect(action_plan.numerator).to eq 4
      expect(action_plan.progress).to eq 57
    end

    it "is 100% once the target is reached" do
      expect(action_plan_with(target_value: 7, previous: 27, current: 41).progress).to eq 100
    end

    it "is 0% when fewer patients are on statins than last quarter" do
      expect(action_plan_with(target_value: 7, previous: 27, current: 25).progress).to eq 0
    end

    it "shows 0 patients instead of a negative number when fewer patients are on statins than last quarter" do
      expect(action_plan_with(target_value: 20, previous: 13, current: 9).numerator).to eq 0
    end

    it "is 100% when there is nothing more to achieve" do
      expect(action_plan_with(target_value: 0, previous: 27, current: 27).progress).to eq 100
    end

    it "is 0% when there is nothing more to achieve but patients dropped" do
      expect(action_plan_with(target_value: 0, previous: 27, current: 25).progress).to eq 0
    end

    it "is 0% when the previous quarter has no data" do
      expect(action_plan_with(target_value: 7, previous: nil, current: 31).progress).to eq 0
    end
  end

  describe "#goal_statement" do
    let(:region) { setup_district_with_facilities[:region] }

    def action_plan_for(indicator, baseline:, goal:)
      target = DrRai::PercentageTarget.create(numeric_value: 7, period: "Q4-2026", baseline_percentage: baseline, goal_percentage: goal)
      DrRai::ActionPlan.new(dr_rai_target: target, dr_rai_indicator: indicator, region: region, statement: "TODO")
    end

    it "describes the goal with the saved percentages" do
      expect(action_plan_for(DrRai::ContactOverduePatientsIndicator.create, baseline: 20, goal: 35).goal_statement)
        .to eq "Goal: Increase calling from 20% to 35%"
      expect(action_plan_for(DrRai::TitrationIndicator.create, baseline: 34, goal: 50).goal_statement)
        .to eq "Goal: Increase titrations from 34% to 50%"
      expect(action_plan_for(DrRai::StatinsIndicator.create, baseline: 15, goal: 25).goal_statement)
        .to eq "Goal: Increase patients prescribed statins from 15% to 25%"
    end

    it "is nil for plans created without the percentages" do
      expect(action_plan_for(DrRai::StatinsIndicator.create, baseline: nil, goal: nil).goal_statement).to be_nil
    end

    it "is nil for indicators without a goal subject" do
      expect(action_plan_for(DrRai::BpFudgingIndicator.create, baseline: 10, goal: 5).goal_statement).to be_nil
    end
  end
end
