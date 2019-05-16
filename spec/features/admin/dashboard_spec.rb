require 'rails_helper'

require 'Pages/dashboard_page'
require 'Pages/log_in_page'
require 'Pages/home_page'
require 'Pages/organizations_page'
require 'Pages/base'

RSpec.feature 'Verify Dashboard', type: :feature do
  let(:owner) {create(:admin)}
  #created organizaiton
  let!(:ihmi) {create(:organization, name: "IHMI")}
  let!(:path) {create(:organization, name: "PATH")}

  #create facility group
  let!(:ihmi_group_bathinda) {create(:facility_group, organization: ihmi, name: "Bathinda")}
  let!(:ihmi_group_mansa) {create(:facility_group, organization: ihmi, name: "Mansa")}
  let!(:path_group) {create(:facility_group, organization: path, name: "Test Facility Group")}

  #assigned 3 clinic to path group
  let!(:path_clinic1) {create(:facility, facility_group: path_group, name: "Dr. Test_01")}
  let!(:path_clinic2) {create(:facility, facility_group: path_group, name: "Dr. Test_02")}
  let!(:path_clinic3) {create(:facility, facility_group: path_group, name: "Dr. Test_03")}

  login_page = LoginPage.new
  dashboard = DashboardPage.new
  home_page = HomePage.new

  context "Verify Dashboard" do
    before(:each) do
      visit root_path
      login_page.do_login(owner.email, owner.password)
    end

  it 'Verify all organization' do
    #asssertion
    expect(dashboard.get_organization_count).to eq(2)
    expect(page).to have_content("IHMI")
    expect(page).to have_content("PATH")
  end

  it 'Verify all facilities' do
checkout    #asssertion
    expect(dashboard.get_facility_count).to eq(3)
    expect(page).to have_content("Bathinda")
    expect(page).to have_content("Mansa")
    expect(page).to have_content("Test Facility Group")
  end

  it 'Verify organisation name/count get updated in dashboard when new org is added via manage section' do
    #total number of organizaiton present in dashborad
    organization_count = dashboard.get_organization_count

    home_page.select_manage_option("Organizations")
    organization = OrganizationsPage.new
    organization.create_new_organization("test", "testDescription")

    #assertion at organization screen
    expect(page).to have_content('Organization was successfully created.')
    org_info =["test", "testDescription"]
    organization.verify_organization_info(org_info)

    home_page.select_main_menu_tab("Dashboard")
    #assertion at dashboard screen
    expect(page).to have_content("test")
    expect(dashboard.get_organization_count).to eq(organization_count + 1)
  end

  it 'click facility group link and verify facility group analytics page' do
    dashboard.click_facility_group_link(path_group.name)
    expect(current_path).to eq analytics_facility_group_path(path_group)

   # assertion at detail page
    expect(dashboard.get_facility_count_at_in_analytics_page).to eq(3)
    expect(page).to have_content(path_clinic1.name)
    expect(page).to have_content(path_clinic2.name)
    expect(page).to have_content(path_clinic3.name)
  end
  end

  it 'SignIn as Owner and verify approval request in dashboard' do
    user = create(:user, sync_approval_status: :requested)

    visit root_path
    login_page.do_login(owner.email, owner.password)
    expect(page).to have_content("Allow access")
    expect(page).to have_content("Deny access")
    #check for user info
    expect(page).to have_content(user.full_name)
    expect(page).to have_content(user.phone_number)
  end
end