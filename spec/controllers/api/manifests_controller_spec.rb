require "rails_helper"

RSpec.describe Api::ManifestsController, type: :controller do
  describe "GET #show" do
    context "in production environments" do
      environments = Dir
        .glob("config/deploy/*.rb")
        .map { |file| Pathname.new(file).basename(".rb").to_s }

      environments.each do |env|
        it "return 200 for #{env}" do
          original_env = ENV["SIMPLE_SERVER_ENV"]
          ENV["SIMPLE_SERVER_ENV"] = env
          allow(File).to receive(:read).with("public/manifest/#{env}.json").and_call_original

          expect(File).to receive(:read).with("public/manifest/#{env}.json")

          get :show

          expect(response).to be_ok
          expect(response.body).to eq(File.read("public/manifest/#{env}.json"))

          ENV["SIMPLE_SERVER_ENV"] = original_env
        end
      end

      it "return 404 for an unknown env" do
        original_env = ENV["SIMPLE_SERVER_ENV"]
        ENV["SIMPLE_SERVER_ENV"] = "unknown"

        get :show

        expect(response).to be_not_found
      end
    end

    context "in non-production environments" do
      environments = %w[development review]

      environments.each do |env|
        it "returns a dynamic manifest for #{env}" do
          original_env = ENV["SIMPLE_SERVER_ENV"]
          original_host = ENV["SIMPLE_SERVER_HOST"]
          original_protocol = ENV["SIMPLE_SERVER_HOST_PROTOCOL"]

          ENV["SIMPLE_SERVER_ENV"] = env
          ENV["SIMPLE_SERVER_HOST"] = "simple.example.com"
          ENV["SIMPLE_SERVER_HOST_PROTOCOL"] = "https"

          get :show

          expect(response).to be_ok
          expect(JSON.parse(response.body)).to eq(
            "v1" => [
              {
                "country_code"=>"IN",
                "display_name"=>"India",
                "endpoint"=>"https://simple.example.com/api/",
                "isd_code"=>"91"
              },
              {
                "country_code"=>"BD",
                "display_name"=>"Bangladesh",
                "endpoint"=>"https://simple.example.com/api/",
                "isd_code"=>"880"
              },
              {
                "country_code"=>"ET",
                "display_name"=>"Ethiopia",
                "endpoint"=>"https://simple.example.com/api/",
                "isd_code"=>"251"
              }
            ]
          )

          ENV["SIMPLE_SERVER_ENV"] = original_env
          ENV["SIMPLE_SERVER_HOST"] = original_host
          ENV["SIMPLE_SERVER_HOST_PROTOCOL"] = original_protocol
        end
      end
    end
  end
end
