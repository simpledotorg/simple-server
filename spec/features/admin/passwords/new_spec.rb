# frozen_string_literal: true

require "features_helper"

RSpec.feature "To test Forgot password functionality", type: :feature do
  let(:owner) { create(:admin, :power_user) }
  login_page = AdminPage::Sessions::New.new
  forgot_password = AdminPage::Passwords::New.new

  it "Owner should be able to click on Forgot password Link" do
    visit root_path
    login_page.click_forgot_password_link
    forgot_password.assert_forgot_password_landing_page
  end

  describe "Owner Provides valid login data and click on forgot password link" do
    it "Verify Owner should be able to click on Forgot password Link " do
      visit root_path
      login_page.set_email_text_box(owner.email)
      login_page.set_password_text_box(owner.password)

      login_page.click_forgot_password_link
      forgot_password.assert_forgot_password_landing_page

      forgot_password.do_reset_password(owner.email)
    end
  end

  it "verify Login link in Forgot password  Page" do
    visit root_path
    login_page.click_forgot_password_link
    forgot_password.click_login_link
    expect(page).to have_content("Login")
  end
end
