require "rails_helper"

RSpec.describe AdminController, type: :controller do
  controller do
    after_action :verify_authorization_attempted, only: [:not_authorized, :authorized, :authorization_not_attempted]

    def not_authorized
      authorize do
        false
      end

      render plain: "Not, authorized"
    end

    def record_not_found
      authorize do
        Facility.find(SecureRandom.uuid)
      end

      render plain: "Not, authorized"
    end

    def authorized
      authorize do
        true
      end

      render plain: "Hello, authorized"
    end

    def authorization_not_attempted
      render plain: "Not, authorization_not_attempted"
    end
  end

  let(:user) { create(:admin, :manager) }

  before do
    sign_in(user.email_authentication)
  end

  context "authorize" do
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

    it "redirects to root_path when referrer url is the same as request url" do
      routes.draw { get "not_authorized" => "admin#not_authorized" }
      request.env["HTTP_REFERER"] = "http://test.host/not_authorized"

      get :not_authorized
      expect(response.headers["Location"]).to eq "http://test.host/"
    end

    it "redirects to referrer url when it is different from request url" do
      routes.draw { get "not_authorized" => "admin#not_authorized" }
      referrer_url = "http://test.host/some_other_url"
      request.env["HTTP_REFERER"] = referrer_url

      get :not_authorized
      expect(response.headers["Location"]).to eq referrer_url
    end

    it "continues to render as usual when truthy is returned" do
      routes.draw { get "authorized" => "admin#authorized" }

      get :authorized
      expect(response.body).to match(/Hello, authorized/)
    end

    it "continues to render as usual when user is power_user" do
      user.update!(access_level: :power_user)
      routes.draw { get "not_authorized" => "admin#not_authorized" }

      get :not_authorized
      expect(response.body).to match(/Not, authorized/)
    end
  end

  context "bust_cache" do
    it "bust_cache is false if the param is not present" do
      routes.draw { get "authorized" => "admin#authorized" }
      get :authorized
      expect(RequestStore[:bust_cache]).to be_falsey
      expect(controller.bust_cache?).to be_falsey
    end

    it "sets bust_cache to true if the param is present" do
      routes.draw { get "authorized" => "admin#authorized" }
      get :authorized, params: {bust_cache: "1"}
      expect(RequestStore[:bust_cache]).to be_truthy
      expect(controller.bust_cache?).to be_truthy
    end
  end

  context "flipper info" do
    it "sends enabled features as datadog tag" do
      Flipper.enable(:enabled_1)
      Flipper.enable(:enabled_2)
      Flipper.disable(:disabled)
      span_double = instance_double("Datadog::Span")

      expect(span_double).to receive(:set_tag).with("features.enabled_1", "enabled")
      expect(span_double).to receive(:set_tag).with("features.enabled_2", "enabled")
      expect(Datadog.tracer).to receive(:active_span).and_return(span_double)
      routes.draw { get "authorized" => "admin#authorized" }
      get :authorized
    end
  end

  context "#verify_authorization_attempted" do
    it "raises an error if authorize is not called but required" do
      routes.draw { get "authorization_not_attempted" => "admin#authorization_not_attempted" }

      expect {
        get :authorization_not_attempted
      }.to raise_error(UserAccess::AuthorizationNotPerformedError)
    end
  end
end
