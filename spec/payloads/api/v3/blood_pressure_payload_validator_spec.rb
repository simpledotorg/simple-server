require "rails_helper"

describe Api::V3::BloodPressurePayloadValidator, type: :model do
  describe "Data validations" do
    it "validates that the blood pressure's facility exists" do
      facility = create(:facility)
      blood_pressure = build_blood_pressure_payload(create(:blood_pressure, facility: facility))
      facility.discard

      validator = Api::V3::BloodPressurePayloadValidator.new(blood_pressure)
      expect(validator.valid?).to be false
    end
  end
end
