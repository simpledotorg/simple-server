# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailAuthentications::SessionsController, type: :controller do
  before :each do
    @request.env["devise.mapping"] = Devise.mappings[:email_authentication]
  end

  describe "#destroy" do
    it "resets the session token on sign out" do
      admin = create(:admin)
      sign_in(admin.email_authentication)
      previous_session_token = admin.email_authentication.session_token
      delete :destroy
      expect(admin.reload.email_authentication.session_token).not_to eq previous_session_token
      expect(admin.reload.email_authentication.session_token).not_to eq nil
    end
  end
end
