require "rails_helper"

RSpec.describe HealthController, type: :controller do
  describe "GET #ping" do
    it "returns OK" do
      get :ping

      expect(response.body).to eq("OK")
      expect(response).to be_successful
    end
  end
end
