# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V3::BloodSugarTransformer do
  describe "to_response" do
    let(:blood_sugar) { FactoryBot.build(:blood_sugar) }

    it "coerces blood_sugar_value to an int" do
      transformed_blood_sugar = Api::V3::BloodSugarTransformer.to_response(blood_sugar)
      expect(transformed_blood_sugar["blood_sugar_value"]).to be_an_instance_of(Integer)
    end
  end
end
