require "rails_helper"

RSpec.describe AdminController, type: :controller do
  controller do
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped
    after_action :verify_authorization_attempted, only: [:not_authorized, :authorized, :authorization_not_attempted]

    def not_authorized
      authorize1 do
        false
      end

      render plain: "Not, authorized"
    end

    def record_not_found
      authorize1 do
        Facility.find(SecureRandom.uuid)
      end

      render plain: "Not, authorized"
    end

    def authorized
      authorize1 do
        true
      end

      render plain: "Hello, authorized"
    end

    def authorization_not_attempted
      render plain: "Not, authorization_not_attempted"
    end
  end

  let(:user) { create(:admin) }

  before do
    sign_in(user.email_authentication)
  end

  context "authorize1" do
    it "redirects to root_path when falsey is returned" do
      routes.draw { get "not_authorized" => "admin#not_authorized" }

      get :not_authorized
      expect(response).to redirect_to(root_path)
    end

    it "redirects to root_path when ActiveRecord::RecordNotFound is raised" do
      routes.draw { get "record_not_found" => "admin#record_not_found" }

      get :record_not_found
      expect(response).to redirect_to(root_path)
    end

    it "continues to render as usual when truthy is returned" do
      routes.draw { get "authorized" => "admin#authorized" }

      get :authorized
      expect(response.body).to match(/Hello, authorized/)
    end
  end

  context "#verify_authorization_attempted" do
    it "raises an error if authorize1 is not called but required" do
      routes.draw { get "authorization_not_attempted" => "admin#authorization_not_attempted" }

      expect {
        get :authorization_not_attempted
      }.to raise_error(UserAccess::AuthorizationNotPerformedError)
    end
  end
end
