# frozen_string_literal: true

require "rails_helper"

RSpec.describe PatientBusinessIdentifier, type: :model do
  describe "Associations" do
    it { should belong_to(:patient) }
    it { should have_one(:passport_authentication) }
  end

  describe "Validations" do
    it { should validate_presence_of(:identifier) }
    it { should validate_presence_of(:identifier_type) }

    context "for bangladesh national IDs" do
      it "cannot be nil" do
        identifier = build(:patient_business_identifier, identifier: nil, identifier_type: "bangladesh_national_id")
        expect(identifier).to_not be_valid
        expect(identifier.errors[:identifier]).to eq(["can't be blank"])
      end

      it "can be blank" do
        identifier = build(:patient_business_identifier, identifier: "", identifier_type: "bangladesh_national_id")
        expect(identifier).to be_valid
      end
    end

    it_behaves_like "a record that validates device timestamps"
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  describe "enums" do
    it {
      should define_enum_for(:identifier_type)
        .with_values(simple_bp_passport: "simple_bp_passport",
          bangladesh_national_id: "bangladesh_national_id",
          sri_lanka_national_id: "sri_lanka_national_id",
          sri_lanka_personal_health_number: "sri_lanka_personal_health_number",
          ethiopia_medical_record: "ethiopia_medical_record",
          india_national_health_id: "india_national_health_id")
        .backed_by_column_of_type(:string)
    }
  end

  describe "#shortcode" do
    let(:business_identifier) { build(:patient_business_identifier) }

    it "returns the shortcode for Simple BP passports" do
      business_identifier.identifier_type = :simple_bp_passport
      business_identifier.identifier = "1a3b5c2d-4e68-f79a-098b-cd7e6f54a3b2"

      expect(business_identifier.shortcode).to eq("135-2468")
    end
  end
end
