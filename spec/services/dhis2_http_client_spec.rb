require "rails_helper"

RSpec.describe Dhis2HttpClient, type: :model do
  let(:url) { "https://dhis2.example.com" }
  let(:username) { "test_user" }
  let(:password) { "test_password" }
  let(:client) { described_class.new(url: url, username: username, password: password) }

  around do |example|
    WebMock.disallow_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  describe "#initialize" do
    it "sets base_url, username, and password" do
      expect(client.base_url).to eq("https://dhis2.example.com")
      expect(client.username).to eq("test_user")
      expect(client.password).to eq("test_password")
    end

    it "removes trailing slash from URL" do
      client_with_slash = described_class.new(url: "https://dhis2.example.com/", username: username, password: password)
      expect(client_with_slash.base_url).to eq("https://dhis2.example.com")
    end
  end

  describe "#bulk_create_data_values" do
    let(:data_values) do
      [
        {data_element: "DE123", org_unit: "ORG456", period: "202401", value: 42},
        {data_element: "DE124", org_unit: "ORG456", period: "202401", value: 10}
      ]
    end

    let(:request_url) { "#{url}/api/dataValueSets" }
    let(:auth_header) { "Basic #{Base64.strict_encode64("#{username}:#{password}")}" }

    context "when request is successful with modern DHIS2 response" do
      let(:success_response) do
        {
          status: "SUCCESS",
          description: "Import process completed successfully",
          importCount: {
            imported: 2,
            updated: 0,
            ignored: 0,
            deleted: 0
          },
          conflicts: []
        }.to_json
      end

      it "returns parsed response with import counts" do
        stub_request(:post, request_url)
          .with(
            headers: {
              "Authorization" => auth_header,
              "Content-Type" => "application/json",
              "Accept" => "application/json"
            },
            body: hash_including(dataValues: array_including(
              hash_including(dataElement: "DE123", orgUnit: "ORG456", period: "202401", value: 42),
              hash_including(dataElement: "DE124", orgUnit: "ORG456", period: "202401", value: 10)
            ))
          )
          .to_return(status: 200, body: success_response)

        result = client.bulk_create_data_values(data_values: data_values)

        expect(result[:status]).to eq("SUCCESS")
        expect(result[:imported]).to eq(2)
        expect(result[:updated]).to eq(0)
        expect(result[:ignored]).to eq(0)
        expect(result[:deleted]).to eq(0)
        expect(result[:conflicts]).to eq([])
      end

      it "transforms snake_case keys to camelCase" do
        stub_request(:post, request_url)
          .with(
            body: hash_including(dataValues: array_including(
              hash_including(
                dataElement: "DE123",
                orgUnit: "ORG456",
                period: "202401",
                value: 42
              )
            ))
          )
          .to_return(status: 200, body: success_response)

        client.bulk_create_data_values(data_values: data_values)
      end
    end

    context "when request is successful with legacy DHIS2 response" do
      let(:legacy_response) do
        {
          status: "OK",
          response: {
            status: "OK",
            importCount: {
              imported: 2,
              updated: 0,
              ignored: 0,
              deleted: 0
            },
            conflicts: []
          }
        }.to_json
      end

      it "handles legacy response format" do
        stub_request(:post, request_url)
          .to_return(status: 200, body: legacy_response)

        result = client.bulk_create_data_values(data_values: data_values)

        expect(result[:status]).to eq("OK")
        expect(result[:imported]).to eq(2)
      end
    end

    context "when data includes category options (Ethiopia case)" do
      let(:data_with_categories) do
        [
          {
            data_element: "DE123",
            org_unit: "ORG456",
            category_option_combo: "CAT789",
            attribute_option_combo: "ATTR012",
            period: "202401",
            value: 42
          }
        ]
      end

      let(:success_response) do
        {status: "SUCCESS", importCount: {imported: 1, updated: 0, ignored: 0, deleted: 0}}.to_json
      end

      it "transforms all keys to camelCase including category options" do
        stub_request(:post, request_url)
          .with(
            body: hash_including(dataValues: array_including(
              hash_including(
                dataElement: "DE123",
                orgUnit: "ORG456",
                categoryOptionCombo: "CAT789",
                attributeOptionCombo: "ATTR012",
                period: "202401",
                value: 42
              )
            ))
          )
          .to_return(status: 200, body: success_response)

        result = client.bulk_create_data_values(data_values: data_with_categories)
        expect(result[:imported]).to eq(1)
      end
    end

    context "when HTTP request fails" do
      it "raises RequestError on timeout" do
        stub_request(:post, request_url).to_timeout

        expect {
          client.bulk_create_data_values(data_values: data_values)
        }.to raise_error(Dhis2HttpClient::RequestError, /timeout/i)
      end

      it "raises RequestError on connection error" do
        stub_request(:post, request_url).to_raise(SocketError)

        expect {
          client.bulk_create_data_values(data_values: data_values)
        }.to raise_error(Dhis2HttpClient::RequestError, /HTTP request failed/i)
      end
    end

    context "when DHIS2 returns HTTP error status" do
      it "raises ResponseError on 401 Unauthorized" do
        stub_request(:post, request_url)
          .to_return(status: 401, body: {message: "Invalid credentials"}.to_json)

        expect {
          client.bulk_create_data_values(data_values: data_values)
        }.to raise_error(Dhis2HttpClient::ResponseError, /HTTP 401.*Invalid credentials/i)
      end

      it "raises ResponseError on 500 Internal Server Error" do
        stub_request(:post, request_url)
          .to_return(status: 500, body: "Internal Server Error")

        expect {
          client.bulk_create_data_values(data_values: data_values)
        }.to raise_error(Dhis2HttpClient::ResponseError, /HTTP 500/i)
      end
    end

    context "when DHIS2 returns error status in response body" do
      let(:error_response) do
        {
          status: "ERROR",
          description: "Import failed",
          conflicts: [
            {object: "dataValue", value: "Data element does not exist"}
          ]
        }.to_json
      end

      it "raises ResponseError with conflict details" do
        stub_request(:post, request_url)
          .to_return(status: 200, body: error_response)

        expect {
          client.bulk_create_data_values(data_values: data_values)
        }.to raise_error(Dhis2HttpClient::ResponseError, /import failed.*ERROR.*Data element does not exist/i)
      end
    end

    context "when response body is invalid JSON" do
      it "raises ResponseError" do
        stub_request(:post, request_url)
          .to_return(status: 200, body: "Not JSON")

        expect {
          client.bulk_create_data_values(data_values: data_values)
        }.to raise_error(Dhis2HttpClient::ResponseError, /Failed to parse JSON/i)
      end
    end

    context "when response includes conflicts but still successful" do
      let(:response_with_ignored) do
        {
          status: "SUCCESS",
          importCount: {
            imported: 1,
            updated: 0,
            ignored: 1,
            deleted: 0
          },
          conflicts: [
            {object: "dataValue", value: "Data value already exists"}
          ]
        }.to_json
      end

      it "returns success with conflict information" do
        stub_request(:post, request_url)
          .to_return(status: 200, body: response_with_ignored)

        result = client.bulk_create_data_values(data_values: data_values)

        expect(result[:status]).to eq("SUCCESS")
        expect(result[:imported]).to eq(1)
        expect(result[:ignored]).to eq(1)
        expect(result[:conflicts].length).to eq(1)
      end
    end
  end
end
