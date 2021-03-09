require "rails_helper"

RSpec.describe "Admin authentication", type: :request do
  include Devise::Test::IntegrationHelpers

  describe "current user state" do
    it "sets the current user into RequestStore for every authenticated request" do
      user = create(:admin, :power_user)
      password = user.password

      allow(RequestStore).to receive(:clear!)

      get "/"
      expect(response).to have_http_status(200)

      post email_authentication_session_path, params: {email_authentication: {email: user.email, password: password}}

      expect(RequestStore.store[:current_user_id]).to eq(user.id)
      Thread.current[:request_store] = {}

      expect(response).to redirect_to("/")

      follow_redirect!

      expect(RequestStore.store[:current_user_id]).to eq(user.id)
      Thread.current[:request_store] = {}

      expect(response).to redirect_to("/my_facilities")

      # get "/logout"
    end
  end
end
