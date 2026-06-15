# frozen_string_literal: true

require "rails_helper"
require "base64"

describe Dhis2::DataValueSetsClient do
  let(:url) { "https://dhis2.example.org" }
  let(:username) { "dhis-user" }
  let(:password) { "dhis-password" }
  let(:client) { described_class.new(url: url, username: username, password: password, timeout: 5) }
  let(:endpoint) { "#{url}/api/dataValueSets" }
  let(:success_response) {
    {
      status: "OK",
      response: {
        status: "SUCCESS",
        importCount: {
          imported: 1,
          updated: 0,
          ignored: 0
        }
      }
    }.to_json
  }

  describe "#bulk_create" do
    it "posts data values to the DHIS2 dataValueSets endpoint" do
      requested_body = nil
      requested_headers = nil
      request = stub_request(:post, endpoint)
        .with { |http_request|
          requested_body = JSON.parse(http_request.body)
          requested_headers = http_request.headers
          true
        }
        .to_return(status: 200, body: success_response, headers: {"Content-Type" => "application/json"})

      response = client.bulk_create(data_values: [
        {
          data_element: "de-id",
          org_unit: "org-unit-id",
          category_option_combo: "category-option-combo-id",
          attribute_option_combo: "attribute-option-combo-id",
          period: "202405",
          value: 42
        }
      ])

      expect(request).to have_been_requested
      expect(requested_headers["Authorization"]).to eq("Basic #{Base64.strict_encode64("#{username}:#{password}")}")
      expect(requested_headers["Accept"]).to include("application/json")
      expect(requested_headers["Content-Type"]).to include("application/json")
      expect(requested_body).to eq(
        "dataValues" => [
          {
            "dataElement" => "de-id",
            "orgUnit" => "org-unit-id",
            "categoryOptionCombo" => "category-option-combo-id",
            "attributeOptionCombo" => "attribute-option-combo-id",
            "period" => "202405",
            "value" => 42
          }
        ]
      )
      expect(response).to eq(JSON.parse(success_response))
    end

    it "raises a request error for non-2xx responses" do
      stub_request(:post, endpoint)
        .to_return(status: 500, body: {status: "ERROR"}.to_json)

      expect {
        client.bulk_create(data_values: [])
      }.to raise_error(Dhis2::RequestError, /HTTP 500/)
    end

    it "raises a request error for network failures" do
      stub_request(:post, endpoint).to_timeout

      expect {
        client.bulk_create(data_values: [])
      }.to raise_error(Dhis2::RequestError, /DHIS2 request failed/)
    end

    it "raises an import error when DHIS2 ignores data values" do
      stub_request(:post, endpoint)
        .to_return(
          status: 200,
          body: {
            status: "OK",
            response: {
              status: "SUCCESS",
              importCount: {
                imported: 0,
                updated: 0,
                ignored: 1
              }
            }
          }.to_json
        )

      expect {
        client.bulk_create(data_values: [])
      }.to raise_error(Dhis2::ImportError, /DHIS2 import failed/)
    end
  end
end
