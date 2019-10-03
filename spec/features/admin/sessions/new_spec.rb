require 'rails_helper'

RSpec.feature 'Owner Login as Admin', type: :feature do
  let(:owner) { create(:admin, :owner) }
  let(:counsellor) { create(:admin, :counsellor) }
  login_page = AdminPage::Sessions::New.new
  dashboard_navigation = Navigations::DashboardPageNavigation.new

  context "owners login and logout" do
    before(:each) do
      visit root_path
      login_page.do_login(owner.email, owner.password)
    end

    it 'Logs in ' do
      dashboard_navigation.validate_owners_home_page
      expect(page).to have_content(owner.email)
    end

    it 'log Out' do
      dashboard_navigation.click_logout_button
      login_page.is_successful_logout_message_present
      login_page.click_successful_message_cross_button
    end
  end
  context "counsellors login and logout" do
    before(:each) do
      visit root_path
      login_page.do_login(counsellor.email, counsellor.password)
    end

    it 'Logs in ' do
      expect(page).to have_content('Patients that are newly registered and need 48-hour adherence follow-up.')
      expect(page).to have_content(counsellor.email)
    end

    it 'log Out' do
      dashboard_navigation.click_logout_button
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
