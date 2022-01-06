# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacilityBusinessIdentifier, type: :model do
  describe "Associations" do
    it { should belong_to(:facility) }
  end

  describe "Validations" do
    # We must define the subject because "identifier" is required for uniqueness validation test
    subject { create(:facility_business_identifier, identifier: "abcd1234") }
    it { should validate_presence_of(:identifier) }
    it { should validate_presence_of(:identifier_type) }
    it { should validate_uniqueness_of(:identifier_type).scoped_to(:facility_id).ignoring_case_sensitivity }
    it { should validate_presence_of(:facility) }
  end
end
