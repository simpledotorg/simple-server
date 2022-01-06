# frozen_string_literal: true

require "swagger_helper"

describe "Help v3 API", swagger_doc: "v3/swagger.json" do
  path "/help.html" do
    get "Sends a static HTML containing help documentation" do
      tags "help"
      produces "text/html"

      response "200", "HTML received" do
        let(:Accept) { "text/html" }

        run_test!
      end
    end
  end
end
