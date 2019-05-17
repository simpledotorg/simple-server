require 'rails_helper'
require 'Pages/log_in_page'
require 'Pages/dashboard_page'
require 'Pages/home_page'
require 'Pages/organizations_page'

RSpec.feature 'Manage Section: Organizaiton Management', type: :feature do
  let!(:ihmi) {create(:organization, name: "IHMI")}
  let!(:ihmi_group) {create(:facility_group, organization: ihmi, name: "Bathinda")}

  home_page = HomePage.new
  org_page = OrganizationsPage.new


  context 'Assign one organizaiton to organization owner' do
    let!(:org_owner) {
      create(
          :admin,
          :organization_owner,
          admin_access_controls: [AdminAccessControl.new(access_controllable: ihmi)])
    }
    it "single organization" do
      visit root_path
      signin(org_owner)
      home_page.select_main_menu_tab("Manage")
      home_page.select_manage_option('Organizations')
      org_info = [ihmi.name, ihmi.description]
      org_page.verify_organization_info(org_info)
    end
  end

  context 'Assign multiple organization to organization owner' do
    let!(:orgs) {create_list(:organization, 3)}
    let(:admin_access_controls) { orgs.map { |org| AdminAccessControl.new(access_controllable: org)}}
    let!(:org_owner1) {
      create(
          :admin,
          :organization_owner,
          admin_access_controls: admin_access_controls)
    }

    it "Verify Multiple Organizaitons" do
      visit root_path
      signin(org_owner1)
      home_page.select_main_menu_tab("Manage")
      home_page.select_manage_option('Organizations')
      expect(page).to have_content(orgs.first.name)
      expect(page).to have_content(orgs.second.name)
      expect(page).to have_content(orgs.third.name)
    end
  end
end