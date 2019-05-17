require 'rails_helper'
require 'Pages/log_in_page'
require 'Pages/dashboard_page'

RSpec.feature 'Login as organization owner', type: :feature do

  let!(:ihmi) {create(:organization, name: "IHMI")}
  let!(:ihmi_group) {create(:facility_group, organization: ihmi, name: "Bathinda")}
  let!(:facility_01) {create(:facility, facility_group: ihmi_group, name: "test_facility")}

  let!(:org_owner) {
    create(
        :admin,
        :organization_owner,
        admin_access_controls: [AdminAccessControl.new(access_controllable: ihmi)])
  }
  dashboard = DashboardPage.new

  context "create organization with one facility group" do
    before(:each) do
      visit root_path
      signin(org_owner)
    end
    it 'Verify Dashboard' do
      #assertion
      expect(page).to have_content(ihmi_group.name)
      expect(page).to have_content(ihmi_group.name)
    end

    it 'click facility group link and verify facility group analytics page' do
      dashboard.click_facility_group_link(ihmi_group.name)
      expect(current_path).to eq analytics_facility_group_path(ihmi_group)
      #assertion at analytics page
      expect(dashboard.get_facility_count_at_in_analytics_page).to eq(1)
    end
  end

  it 'verify approval request' do
    user = create(:user, sync_approval_status: :requested, facility: facility_01)

    visit root_path
    signin(org_owner)
    expect(page).to have_content("1 user waiting for access")
    expect(page).to have_content("Allow access")
    expect(page).to have_content("Deny access")
    #check for user info
    expect(page).to have_content(user.full_name)
    expect(page).to have_content(user.phone_number)
  end

end