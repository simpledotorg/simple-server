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

  describe ".backfill_action_items!" do
    let(:district_with_facilities) { setup_district_with_facilities }
    let(:region) { district_with_facilities[:region] }
    let(:indicator) { DrRai::ContactOverduePatientsIndicator.create }

    it "splits multiline actions into ordered incomplete items" do
      action_plan = create(
        :action_plan,
        region: region,
        dr_rai_indicator: indicator,
        actions: "First\n\nSecond\n"
      )
      action_plan.action_items.delete_all

      described_class.backfill_action_items!

      items = action_plan.action_items.reload
      expect(items.map(&:body)).to eq(["First", "Second"])
      expect(items.map(&:position)).to eq([0, 1])
      expect(items.map(&:completed_at)).to all(be_nil)
    end
  end

  describe "#replace_action_items!" do
    let(:district_with_facilities) { setup_district_with_facilities }
    let(:region) { district_with_facilities[:region] }
    let(:indicator) { DrRai::ContactOverduePatientsIndicator.create }

    it "keeps completed_at when a row is updated and drops blank bodies" do
      action_plan = create(:action_plan, region: region, dr_rai_indicator: indicator, actions: "Original task")
      item = action_plan.action_items.first
      item.update!(completed_at: Time.current)

      action_plan.replace_action_items!([
        {id: item.id, body: "Revised task"},
        {body: "  "},
        {body: "New task"}
      ])

      expect(item.reload.body).to eq("Revised task")
      expect(item.completed_at).to be_present
      expect(action_plan.action_items.reload.map(&:body)).to eq(["Revised task", "New task"])
      expect(action_plan.reload.actions).to eq("Revised task\nNew task")
    end
  end

  describe "#tasks_checkable?" do
    let(:district_with_facilities) { setup_district_with_facilities }
    let(:region) { district_with_facilities[:region] }
    let(:indicator) { DrRai::ContactOverduePatientsIndicator.create }
    let(:action_plan) do
      create(
        :action_plan,
        region: region,
        dr_rai_indicator: indicator,
        dr_rai_target: create(:target, :percentage, period: "Q2-2025", indicator: indicator)
      )
    end

    it "is true on the last day of the quarter and through the following month" do
      expect(action_plan.tasks_checkable?(on: Date.new(2025, 6, 30))).to be(true)
      expect(action_plan.tasks_checkable?(on: Date.new(2025, 7, 31))).to be(true)
    end

    it "is false the day after the following month" do
      expect(action_plan.tasks_checkable?(on: Date.new(2025, 8, 1))).to be(false)
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
