# frozen_string_literal: true

require "swagger_helper"

describe "states v4 API", swagger_doc: "v4/swagger.json" do
  path "/states" do
    get "Lists available state names" do
      tags "States"

      response "200", "returns state names" do
        let(:request_facility) { create(:facility) }

        schema Api::V4::Schema.states_response
        run_test!
      end
    end
  end
end
