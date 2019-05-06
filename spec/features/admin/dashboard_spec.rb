require 'rails_helper'
require 'Pages/dashboard_page'
require 'Pages/log_in_page'
require 'Pages/home_page'
require 'Pages/organizations_page'
require 'Pages/base'

RSpec.feature 'Verify Dashboard', type: :feature do
  let(:owner) {create(:admin)}
  let!(:ihmi) {create(:organization, name: "IHMI")}
  let!(:path) {create(:organization, name: "PATH")}

  loginpage = LoginPage.new
  dashboard = DashboardPage.new
  homepage = HomePage.new

  it 'Verify organization is displayed in dashboard' do
    visit root_path
    loginpage.do_login(owner.email, owner.password)
    #asssertion
    expect(dashboard.get_organization_count).to eq(2)
    expect(page).to have_content("IHMI")
    expect(page).to have_content("PATH")
  end

  it 'Verify organisation name/count get updated in dashboard when new org is added via manage section' do

    visit root_path
    loginpage.do_login(owner.email, owner.password)
    #total number of organizaiton present in dashborad
    organization_count = dashboard.get_organization_count

    homepage.select_manage_option("Organizations")
    organization = OrganizationsPage.new
    organization.create_new_organization("test", "testDescription")

    #assertion at organization screen
    expect(page).to have_content('Organization was successfully created.')
    organization.verify_organization_info

    homepage.select_main_menu_tab("Dashboard")
    #assertion at dashboard screen
    expect(page).to have_content("test")
    expect(dashboard.get_organization_count).to eq(organization_count + 1)
  end

  it 'SignIn as Owner and verify approval request in dashboard' do
    user = create(:user, sync_approval_status: :requested)
    visit root_path
    loginpage.do_login(owner.email, owner.password)

    expect(page).to have_content("Allow access")
    expect(page).to have_content("Deny access")
    #check for user info
    expect(page).to have_content(user.full_name)
    expect(page).to have_content(user.phone_number)
  end
end