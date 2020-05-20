require "rails_helper"

RSpec.describe Api::ManifestsController, type: :controller do
  describe "GET #show" do
    ENVS = Dir
           .glob("config/deploy/*.rb")
           .map { |file| Pathname.new(file).basename(".rb").to_s }

    ENVS.each do |env|
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
end
