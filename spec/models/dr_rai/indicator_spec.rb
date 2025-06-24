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
end
