require "rails_helper"

RSpec.describe Messaging::Bsnl::Error do
  describe "#new" do
    it "puts a reason for known error messages" do
      expect(described_class.new("Invalid").reason).to eq(:invalid_phone_number)
    end
  end
end
