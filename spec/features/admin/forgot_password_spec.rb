require 'rails_helper'

RSpec.feature 'To test Forgot password functionality', type: :feature do

    let(:owner) { create(:admin) }
    login_page = AdminPageSignIn.new
    forgot_password = AdminPasswordPageNew.new

    it 'Owner should be able to click on Forgot password Link' do
      visit root_path
      login_page.click_forgot_password_link
      forgot_password.assert_forgot_password_landing_page
    end

    describe 'Owner Provides valid login data and click on forgot password link' do

      it 'Verify Owner should be able to click on Forgot password Link ' do

        visit root_path
        login_page.set_email_text_box(owner.email)
        login_page.set_password_text_box(owner.password)

        login_page.click_forgot_password_link
        forgot_password.assert_forgot_password_landing_page

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
      forgot_password.click_on_unlock_instruction_link
      AdminUnlockPageNew.new.resend_unlock_instruction(owner.email)
    end
  end

