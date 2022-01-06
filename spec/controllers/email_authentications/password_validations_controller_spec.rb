# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailAuthentications::PasswordValidationsController, type: :request do
  describe "#create" do
    it "returns a list of all errors for the password" do
      post "/email_authentications/validate", params: {password: "I have no numbers"}
      expected_response = {"errors" => ["needs_number"]}
      expect(response.status).to eq 200
      expect(JSON.parse(response.body)).to eq(expected_response)
    end

    it "returns no errors if the password is valid" do
      post "/email_authentications/validate", params: {password: "Resolve2SaveLives"}
      expected_response = {"errors" => []}
      expect(response.status).to eq 200
      expect(JSON.parse(response.body)).to match_array(expected_response)
    end
  end
end
