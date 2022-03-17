require "features_helper"

RSpec.feature "Owner Login as Admin", type: :feature do
  let(:facility) { create(:facility) }
  let(:owner) { create(:admin, :power_user) }
  let(:counsellor) { create(:admin, :call_center, :with_access, resource: facility) }
  login_page = AdminPage::Sessions::New.new
  dashboard_navigation = Navigations::DashboardPageNavigation.new

  context "owners login and logout" do
    before(:each) do
      visit root_path
      login_page.do_login(owner.email, owner.password)
    end

    it "logs in" do
      dashboard_navigation.validate_owners_home_page
      dashboard_navigation.open_more
      expect(page).to have_content(owner.email)
    end

    it "logs out" do
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

    it "logs in" do
      expect(page).to have_content("Patients that are overdue for a follow-up visit.")
      dashboard_navigation.hover_nav
      expect(page).to have_content(counsellor.email)
    end

    it "logs out" do
      dashboard_navigation.click_logout_button
      login_page.is_successful_logout_message_present
      login_page.click_successful_message_cross_button
    end
  end
  it "login with Invalid data" do
    visit root_path
    login_page.do_login(owner.email, "")
    login_page.is_errormessage_present
    login_page.click_errormessage_cross_button
  end
end
