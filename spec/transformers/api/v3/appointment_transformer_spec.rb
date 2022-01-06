# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V3::AppointmentTransformer do
  describe "to_response" do
    let(:appointment) { FactoryBot.build(:appointment) }

    it "removes user_id from appointment response hashes" do
      transformed_appointment = Api::V3::AppointmentTransformer.to_response(appointment)
      expect(transformed_appointment).not_to include("user_id")
    end
  end
end
