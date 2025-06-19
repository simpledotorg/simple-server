require 'rails_helper'

RSpec.describe DrRai::PercentageTarget, type: :model do
  describe "type" do
    it 'should be "PercentageTarget"' do
      expect(DrRai::PercentageTarget.new.type).to eq "DrRai::PercentageTarget"
    end
  end

  describe "validations:" do
    it "numeric_value must exist" do
      new_target = DrRai::Target.new
      expect(new_target).not_to be_valid
      expect(new_target.errors.added?(:numeric_value, :blank)).to be_truthy
    end
  end
end
