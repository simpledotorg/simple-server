require 'rails_helper'
require 'Pages/logIn_page'
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

    loginpage.forgotPasswordLink.click
    assert_forgot_password_landing_page(page)
  end



  describe 'Owner Provides valid login data and click on forgot password link' do

    it 'Verify Owner should be able to click on Forgot password Link ' do

      visit root_path
      loginpage.emailTextBox.set(owner.email)
      loginpage.passwordTextBox.set(owner.password)

      loginpage.forgotPasswordLink.click
      assert_forgot_password_landing_page(page)

      forgotpassword.doResetPassword(owner.email)
      expect(page).to have_no_content(forgotpassword.message)

    end
  end


    it 'verify Login link in Forgot password  Page' do

      visit root_path
      loginpage.forgotPasswordLink.click
      forgotpassword.login.click
      expect(page).to have_no_content(loginpage.loginButton)
    end


    it 'verify unlock instruction link in Forgot Password Page' do
      visit root_path
      loginpage.forgotPasswordLink.click
      forgotpassword.resendUnlockInstruction(owner.email)
    end

end

