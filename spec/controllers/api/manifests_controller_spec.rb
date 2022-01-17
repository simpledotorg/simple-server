require "rails_helper"

RSpec.describe Api::ManifestsController, type: :controller do
  describe "GET #show" do
    render_views

    before do
      # set default stub so other calls to ENV pass thorugh
      allow(ENV).to receive(:[]).and_call_original
    end

    context "in production environments" do
      environments = Dir
        .glob("config/deploy/*.rb")
        .map { |file| Pathname.new(file).basename(".rb").to_s }

      environments.each do |env|
        it "return 200 for #{env}" do
          allow(ENV).to receive(:[]).with("SIMPLE_SERVER_ENV").and_return(env)
          allow(File).to receive(:read).with("public/manifest/#{env}.json").and_call_original

          expect(File).to receive(:read).with("public/manifest/#{env}.json")

          get :show

          expect(response).to be_ok
          expect(response.body).to eq(File.read("public/manifest/#{env}.json"))
        end
      end

      it "return 404 for an unknown env" do
        original_env = ENV["SIMPLE_SERVER_ENV"]
        allow(ENV).to receive(:[]).with("SIMPLE_SERVER_ENV").and_return("unknown")

        get :show

        expect(response).to be_not_found

        allow(ENV).to receive(:[]).with("SIMPLE_SERVER_ENV").and_return(original_env)
      end
    end

    context "in non-production environments" do
      environments = %w[development review android_review]

      environments.each do |env|
        it "returns a dynamic manifest for #{env}" do
          allow(ENV).to receive(:[]).with("SIMPLE_SERVER_ENV").and_return(env)
          allow(ENV).to receive(:[]).with("SIMPLE_SERVER_HOST").and_return("simple.example.com")
          allow(ENV).to receive(:[]).with("SIMPLE_SERVER_HOST_PROTOCOL").and_return("https")

          get :show

          expect(response).to be_ok

          parsed_body = JSON.parse(response.body)
          pp env
          pp parsed_body
          expect(parsed_body["v1"]).to eq(v1_response)
          expect(parsed_body["v2"]).to eq(v2_response)
        end

        let(:v1_response) do
          [
            {
              "country_code" => "IN",
              "display_name" => "India",
              "endpoint" => "https://simple.example.com/api/",
              "isd_code" => "91"
            },
            {
              "country_code" => "BD",
              "display_name" => "Bangladesh",
              "endpoint" => "https://simple.example.com/api/",
              "isd_code" => "880"
            },
            {
              "country_code" => "ET",
              "display_name" => "Ethiopia",
              "endpoint" => "https://simple.example.com/api/",
              "isd_code" => "251"
            },
            {
              "country_code" => "US",
              "display_name" => "United States",
              "endpoint" => "https://simple.example.com/api/",
              "isd_code" => "1"
            },
            {
              "country_code" => "UK",
              "display_name" => "United Kingdom",
              "endpoint" => "https://simple.example.com/api/",
              "isd_code" => "44"
            }
          ]
        end

        let(:v2_response) do
          {
            "countries" => [
              {
                "country_code" => "IN",
                "display_name" => "India",
                "isd_code" => "91",
                "deployments" => [
                  {
                    "display_name" => "India",
                    "endpoint" => "https://simple.example.com/api/"
                  }
                ]
              },
              {
                "country_code" => "BD",
                "display_name" => "Bangladesh",
                "isd_code" => "880",
                "deployments" => [
                  {
                    "display_name" => "Bangladesh",
                    "endpoint" => "https://simple.example.com/api/"
                  }
                ]
              },
              {
                "country_code" => "ET",
                "display_name" => "Ethiopia",
                "isd_code" => "251",
                "deployments" => [
                  {
                    "display_name" => "Ethiopia",
                    "endpoint" => "https://simple.example.com/api/"
                  }
                ]
              },
              {
                "country_code" => "US",
                "display_name" => "United States",
                "isd_code" => "1",
                "deployments" => [
                  {
                    "display_name" => "United States",
                    "endpoint" => "https://simple.example.com/api/"
                  }
                ]
              },
              {
                "country_code" => "UK",
                "display_name" => "United Kingdom",
                "isd_code" => "44",
                "deployments" => [
                  {
                    "display_name" => "United Kingdom",
                    "endpoint" => "https://simple.example.com/api/"
                  }
                ]
              }
            ]
          }
        end
      end
    end
  end
end
