# frozen_string_literal: true

require "rails_helper"

RSpec.describe Address, type: :model do
  describe "Validations" do
    it_behaves_like "a record that validates device timestamps"
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  describe ".has_street_address?" do
    let(:address_without_street_address) { create(:address, :no_street_address) }
    let(:address_with_street_address) { create(:address) }

    it "should return false for an address without a street address" do
      expect(address_without_street_address.has_street_address?).to be_falsey
    end

    it "should return true for an address with a street address" do
      expect(address_with_street_address.has_street_address?).to be_truthy
    end
  end
end
