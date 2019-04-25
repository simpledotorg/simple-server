require 'rails_helper'
require 'Pages/logIn_page'
require 'Pages/common_page'
require 'Pages/home_page'


RSpec.feature 'Owner Login as Admin', type: :feature do
  let(:owner) {create(:admin)}
  loginpage = LoginPage.new
  homepage = HomePage.new
  commonpage = CommonPage.new


  describe 'Verify Owners login for valid  and invalid data' do

    it 'Verify Owner logs in successfully and View HomePage ' do
      visit root_path
      loginpage.doLogin(owner.email, owner.password)
      homepage.validateOwnersHomePage
      expect(page).to have_content(owner.email)
    end


    it 'Verify Login for invalid data' do
      visit root_path
      loginpage.doLogin(owner.email, "password")

      commonpage.verifyText(loginpage.errorMessage, "Invalid Email or password. ×")
      loginpage.messageCrossBtn
      expect(page).to have_no_content(loginpage.errorMessage)

    end

  end

  it ' Owner logs out' do

    visit root_path
    loginpage.doLogin(owner.email, owner.password)
    homepage.clickLogoutButton

    commonpage.verifyText(loginpage.succefulLogoutMessage, 'Signed out successfully.')
    expect(page).to have_content('Login')

    loginpage.messageCrossBtn.click
    expect(page).to have_no_content(loginpage.succefulLogoutMessage)
  end





end


