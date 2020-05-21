require "rails_helper"

RSpec.describe Api::ManifestsController, type: :controller do
  describe "GET #show" do
    ENVS = Dir
      .glob("config/deploy/*.rb")
      .map { |file| Pathname.new(file).basename(".rb").to_s }
      .append("development")

    ENVS.each do |env|
      it "return 200 for #{env}" do
        expect(ENV).to receive(:[]).with("SIMPLE_SERVER_ENV").and_return(env)
        get :show
        expect(response).to be_ok
        expect(response.body).to eq(File.read("public/manifest/#{env}.json"))
      end
    end

    it "return 404 for an unknown env" do
      expect(ENV).to receive(:[]).with("SIMPLE_SERVER_ENV").and_return("unknown")
      get :show
      expect(response).to be_not_found
    end
  end
end
