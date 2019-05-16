require 'rails_helper'

RSpec.feature 'Owner Login as Admin', type: :feature do
  let(:owner) { create(:admin) }
  login_page = LoginPage.new
  home_page = HomePage.new

  before(:each) do
    visit root_path
    login_page.do_login(owner.email, owner.password)
  end

  it 'Valid data ' do
    home_page.validate_owners_home_page
    expect(page).to have_content(owner.email)
  end

  it 'Invalid data' do
    login_page.is_errormessage_present
    login_page.click_errormessage_cross_button
  end

  it 'log Out' do
    home_page.click_logout_button
    login_page.is_successful_logout_message_present
    login_page.click_successful_message_cross_button
  end
end


