require 'rails_helper'
require 'Pages/log_in_page'
require 'Pages/home_page'
require 'Pages/base'

RSpec.feature 'Owner Login as Admin', type: :feature do
  let(:owner) {create(:admin)}
  loginpage = LoginPage.new
  homepage = HomePage.new

  before(:each) do
    visit root_path
    loginpage.do_login(owner.email, owner.password)
  end

  it 'Valid data ' do
    homepage.validate_owners_home_page
    expect(page).to have_content(owner.email)
  end

  it 'Invalid data' do
    loginpage.is_errormessage_present
    loginpage.click_errormessage_cross_button
  end

  it 'log Out' do
    homepage.click_logout_button
    loginpage.is_successful_logout_message_present
    loginpage.click_successful_message_cross_button
  end
end


