require "rails_helper"

RSpec.describe "Admin authentication", type: :request do
  describe "GET /admin_authentication_spec.rbs" do
    it "works! (now write some real specs)" do
      get admin_authentication_spec.rbs_path
      expect(response).to have_http_status(200)
    end
  end
end
