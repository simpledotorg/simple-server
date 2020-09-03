require "rails_helper"

RSpec.feature "Owner Login as Admin", type: :feature do
  let(:owner) { create(:admin, :power_user) }
  let(:counsellor) { create(:admin, :call_center) }
  let!(:facility) { create(:facility) }
  login_page = AdminPage::Sessions::New.new
  dashboard_navigation = Navigations::DashboardPageNavigation.new
  before(:each) do
    enable_flag(:new_permissions_system_aug_2020, owner)
    enable_flag(:new_permissions_system_aug_2020, counsellor)
  end

  after(:each) do
    disable_flag(:new_permissions_system_aug_2020, owner)
    disable_flag(:new_permissions_system_aug_2020, counsellor)
  end

  context "owners login and logout" do
    before(:each) do
      visit root_path
      login_page.do_login(owner.email, owner.password)
    end

    it "Logs in " do
      dashboard_navigation.validate_owners_home_page
      expect(page).to have_content(owner.email)
    end

    it "log Out" do
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

    it "Logs in " do
      expect(page).to have_content("Patients that are overdue for a follow-up visit.")
      expect(page).to have_content(counsellor.email)
    end

    it "log Out" do
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
