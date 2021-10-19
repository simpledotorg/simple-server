require "rails_helper"

RSpec.describe "Admin authentication", type: :request do
  include Devise::Test::IntegrationHelpers

  describe "current user state" do
    before do
      # to ensure request store doesn't get cleared after every request
      allow(RequestStore).to receive(:clear!)
    end

    it "sets the current user into RequestStore for every authenticated request" do
      user = create(:admin, :power_user)
      password = user.password

      get "/"
      expect(response).to have_http_status(200)

      post email_authentication_session_path, params: {email_authentication: {email: user.email, password: password}}

      expect(RequestStore.store[:current_user][:id]).to eq(user.id)
      expect(RequestStore.store[:current_user][:access_level]).to eq("power_user")
      Thread.current[:request_store] = {}

      expect(response).to redirect_to("/")

      follow_redirect!

      expect(RequestStore.store[:current_user][:id]).to eq(user.id)
      expect(RequestStore.store[:current_user][:access_level]).to eq("power_user")
      Thread.current[:request_store] = {}

      expect(response).to redirect_to("/my_facilities")

      delete "/email_authentications/sign_out"

      expect(RequestStore.store[:current_user]).to be_nil
    end
  end

end
