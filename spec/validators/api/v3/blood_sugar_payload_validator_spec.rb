require "rails_helper"

describe Api::V3::BloodSugarPayloadValidator, type: :model do
  describe "Data validations" do
    it "validates that the blood sugar's facility exists" do
      facility = create(:facility)
      blood_sugar = build_blood_sugar_payload(create(:blood_sugar, facility: facility))
      facility.discard

      validator = described_class.new(blood_sugar)
      expect(validator.valid?).to be false
    end
  end
end
