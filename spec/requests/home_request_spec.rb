# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Homes", type: :request do
  include Devise::Test::IntegrationHelpers
  describe "GET /index" do
    it "returns http success" do
      user = create(:admin, :power_user)
      password = user.password
      Flipper.enable(:dashboard_ui_refresh, user)

      post email_authentication_session_path, params: {email_authentication: {email: user.email, password: password}}
      follow_redirect!

      get "/home"
      expect(response).to have_http_status(:success)
    end
  end
end
