require "rails_helper"

RSpec.describe DrRai::NumericTarget, type: :model do
  describe "type" do
    it 'should be "NumericTarget"' do
      expect(DrRai::NumericTarget.new.type).to eq "DrRai::NumericTarget"
    end
  end

  describe "validations:" do
    it "numeric_value must exist" do
      new_target = DrRai::NumericTarget.new
      expect(new_target).not_to be_valid
      expect(new_target.errors.added?(:numeric_value, :blank)).to be_truthy
    end
  end
end
