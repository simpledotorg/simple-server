require "rails_helper"

RSpec.describe DrRai::Target, type: :model do
  describe "validations:" do
    it "periods must exist" do
      new_target = DrRai::Target.new
      expect(new_target).not_to be_valid
      expect(new_target.errors.added?(:period, :blank)).to be_truthy
    end
  end
end
