require "rails_helper"

INVALID_PERIODS = %w[
  01_2025
  1_2025
  Q1_23
  01-2025
  1-2025
  Q1-23
]

RSpec.describe DrRai::Target, type: :model do
  describe "validations:" do
    it "periods must exist" do
      new_target = DrRai::Target.new
      expect(new_target).not_to be_valid
      expect(new_target.errors.added?(:period, :blank)).to be_truthy
    end

    INVALID_PERIODS.each do |period|
      it "#{period} is not a valid period format" do
        target = DrRai::Target.new period: "01-2025"
        expect(target).not_to be_valid
        expect(target.errors.of_kind?(:period, :invalid)).to be_truthy
      end
    end

    it "Q1-2023 is a valid period format" do
      target = DrRai::Target.new period: "Q1-2025"
      expect(target).to be_valid
    end
  end
end
