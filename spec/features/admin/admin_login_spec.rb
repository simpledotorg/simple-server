require 'rails_helper'

RSpec.feature 'Owner Login as Admin', type: :feature do
  let(:email) { Faker::Internet.email }
  let(:password) { Faker::Internet.password }
  let(:owner) { create(:master_user, :with_email_authentication, email: email, password: password) }
  login_page = LoginPage.new
  home_page = HomePage.new

  context "owners login and logout" do
    before(:each) do
      visit root_path
      login_page.do_login(email, password)
    end

    it 'Logs in ' do
      home_page.validate_owners_home_page
      expect(page).to have_content(owner.email)
    end

    it 'log Out' do
      home_page.click_logout_button
      login_page.is_successful_logout_message_present
      login_page.click_successful_message_cross_button
    end
  end
  it 'login with Invalid data' do
    visit root_path
    login_page.do_login(owner.email, "")
    login_page.is_errormessage_present
    login_page.click_errormessage_cross_button
  end
end
