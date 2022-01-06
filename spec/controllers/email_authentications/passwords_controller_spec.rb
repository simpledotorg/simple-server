# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailAuthentications::PasswordsController, type: :controller do
  before :each do
    @request.env["devise.mapping"] = Devise.mappings[:email_authentication]
  end

  describe "#edit" do
    it "renders the edit page when the reset token is valid" do
      auth = build(:email_authentication)
      token = auth.send_reset_password_instructions
      put :edit, params: {reset_password_token: token}
      expect(response).to render_template "edit"
    end

    it "renders the expired reset token page when the reset token is expired" do
      auth = build(:email_authentication)
      token = auth.send_reset_password_instructions
      expired_sent_time = Devise.reset_password_within + 1.hour
      auth.update(reset_password_sent_at: expired_sent_time)
      put :edit, params: {reset_password_token: token}
      expect(response).to render_template "expired_reset_token"
    end

    it "renders the expired reset token page when devise does not find the user by token" do
      auth = build(:email_authentication)
      auth.send_reset_password_instructions

      put :edit, params: {reset_password_token: "heyheyhey"}
      expect(response).to render_template "expired_reset_token"
    end
  end
end
