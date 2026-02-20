require "rails_helper"

RSpec.describe DrRai::Indicator, type: :model do
  describe "validations" do
    it "should be singleton" do
      DrRai::ContactOverduePatientsIndicator.create
      new_same_indicator = DrRai::ContactOverduePatientsIndicator.new
      expect(new_same_indicator).not_to be_valid
      expect(new_same_indicator.errors.of_kind?(:type, :taken)).to be_truthy
    end
  end

  describe "#has_action_plans?" do
    around do |xmpl|
      Timecop.freeze("June 22 2022 22:22 GMT") { xmpl.run }
    end

    let(:region) { setup_district_with_facilities[:region] }
    let(:this_period) { Period.quarter(Date.today) }
    let(:another_period) { Period.quarter(5.months.ago) }

    let(:the_indicator) { create(:indicator, type: "ExistingIndicator") }

    context "when there's an action plan of the same type" do
      before do
        create(:action_plan,
          region: region,
          dr_rai_indicator: the_indicator,
          dr_rai_target: create(:target, :percentage, indicator: the_indicator, period: this_period.value.to_s))
      end

      context "in that period" do
        it "is true" do
          expect(the_indicator.has_action_plans?(region, this_period)).to be_truthy
        end
      end
    end
  end
end
