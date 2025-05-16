require "rails_helper"

RSpec.describe "CustomSwaggerController", type: :request do
  let(:version) { "v4" }

  let(:swagger_path) { Rails.root.join("swagger", version, "swagger.json") }
  let(:import_path) { Rails.root.join("swagger", version, "import.json") }

  before do
    allow(Rails.configuration).to receive(:application_brand_name).and_return("TestBrand")
    allow(Rails.configuration).to receive(:eng_email_id).and_return("eng@example.com")

    # Stub Rails.root.join to return fixture paths
    allow(Rails.root).to receive(:join).and_call_original
    allow(Rails.root).to receive(:join).with("swagger", version, "swagger.json").and_return(swagger_path)
    allow(Rails.root).to receive(:join).with("swagger", version, "import.json").and_return(import_path)
  end

  describe "GET /api-docs/:version/swagger.json" do
    context "when swagger.json file exists" do
      it "returns 200 with customized title and description" do
        get "/api-docs/#{version}/swagger.json"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json["info"]["title"]).to eq("TestBrand")
        expect(json["info"]["description"]).to include("TestBrand")
        expect(json["info"]["contact"]["email"]).to eq("eng@example.com")
      end
    end

    context "when swagger.json does not exist" do
      before do
        fake_path = Pathname.new("/nonexistent/path/swagger.json")
        allow(Rails.root).to receive(:join).with("swagger", version, "swagger.json").and_return(fake_path)
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(fake_path).and_return(false)
      end

      it "returns 404" do
        get "/api-docs/#{version}/swagger.json"

        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("Swagger file for #{version} not found")
      end
    end
  end

  describe "GET /api-docs/:version/import.json" do
    context "when import.json file exists" do
      it "returns 200 with customized content" do
        get "/api-docs/#{version}/import.json"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json["info"]["title"]).to eq("TestBrand")
        expect(json["info"]["description"]).to include("TestBrand")
        expect(json["paths"]["/import"]["put"]["summary"]).to include("TestBrand")
        expect(json["definitions"]["patient"]["properties"]["name"]["description"]).to include("TestBrand")
        expect(json["info"]["contact"]["email"]).to eq("eng@example.com")
        expect(json['definitions']['contact_point']['properties']['use']['description']).to include("TestBrand")
        expect(json['definitions']['appointment']['properties']['status']['description']).to include("TestBrand")
        expect(json['definitions']['medication_request']['properties']['dosageInstruction']['items']['properties']['timing']['properties']['code']['description']).to include("TestBrand")
        expect(json['definitions']['appointment']['properties']['start']['description']).to include("TestBrand")
      end
    end

    context "when import.json does not exist" do
      before do
        fake_path = Pathname.new("/nonexistent/path/swagger.json")
        allow(Rails.root).to receive(:join).with("swagger", version, "import.json").and_return(fake_path)
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(fake_path).and_return(false)
      end

      it "returns 404" do
        get "/api-docs/#{version}/import.json"

        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("Swagger file for #{version} not found")
      end
    end
  end
end
