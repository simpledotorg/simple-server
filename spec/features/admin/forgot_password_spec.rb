require 'rails_helper'

RSpec.feature 'To test Forgot password functionality', type: :feature do
  skip "TODO: update tests to match new UI" do
    def assert_forgot_password_landing_page(page)
      expect(page).to have_content('Email')
      expect(page).to have_field('admin_email')
      expect(page).to have_selector("input[name='commit']")
      expect(page).to have_content('Login')
    end

    let(:owner) { create(:admin) }
    login_page = LoginPage.new
    forgot_password = ForgotPassword.new

    it 'Owner should be able to click on Forgot password Link' do
      visit root_path
      login_page.click_forgot_password_link
      assert_forgot_password_landing_page(page)
    end

    describe 'Owner Provides valid login data and click on forgot password link' do

      it 'Verify Owner should be able to click on Forgot password Link ' do

        visit root_path
        login_page.set_email_text_box(owner.email)
        login_page.set_password_text_box(owner.password)

        login_page.click_forgot_password_link
        assert_forgot_password_landing_page(page)

        forgot_password.do_reset_password(owner.email)
      end
    end

    it 'verify Login link in Forgot password  Page' do
      visit root_path
      login_page.click_forgot_password_link
      forgot_password.click_login_link
      expect(page).to have_content("Login")
    end

    it 'verify unlock instruction link in Forgot Password Page' do
      visit root_path
      login_page.click_forgot_password_link
      forgot_password.resend_unlock_instruction(owner.email)
    end
  end
end

