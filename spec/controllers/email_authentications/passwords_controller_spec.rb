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

    it "responds successfully when the reset token is expired" do
      auth = build(:email_authentication)
      token = auth.send_reset_password_instructions
      auth.update_attribute(:reset_password_sent_at, 7.hours.ago)
      put :edit, params: {reset_password_token: token}
      expect(response).to render_template "expired_reset_token"
    end
  end
end
