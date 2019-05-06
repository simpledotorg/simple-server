require 'rails_helper'
require 'Pages/log_in_page'
require 'Pages/forgot_password_page'

RSpec.feature 'To test Forgot password functionality', type: :feature do
  def assert_forgot_password_landing_page(page)
    expect(page).to have_content('Email')
    expect(page).to have_field('admin_email')
    expect(page).to have_selector("input[name='commit']")
    expect(page).to have_content('Login')
  end

  let(:owner) {create(:admin)}
  loginpage = LoginPage.new
  forgotpassword =ForgotPassword.new

  it 'Owner should be able to click on Forgot password Link' do
    visit root_path
    loginpage.click_forgot_password_link
    assert_forgot_password_landing_page(page)
  end

  describe 'Owner Provides valid login data and click on forgot password link' do

    it 'Verify Owner should be able to click on Forgot password Link ' do

      visit root_path
      loginpage.set_email_text_box(owner.email)
      loginpage.set_password_text_box(owner.password)

      loginpage.click_forgot_password_link
      assert_forgot_password_landing_page(page)

      forgotpassword.do_reset_password(owner.email)
    end
  end

    it 'verify Login link in Forgot password  Page' do
      visit root_path
      loginpage.click_forgot_password_link
      forgotpassword.click_login_link
      expect(page).to have_content("Login")
    end

    it 'verify unlock instruction link in Forgot Password Page' do
      visit root_path
      loginpage.click_forgot_password_link
      forgotpassword.resend_unlock_instruction(owner.email)
    end
end

