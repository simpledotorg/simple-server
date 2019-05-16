require 'rails_helper'
require 'Pages/log_in_page'
require 'Pages/facility_page'
require 'Pages/create_update_facility_group_form_page'
require 'Pages/create_update_facility_form_page'
require 'Pages/facility_detail_page'

RSpec.feature 'Manage -facility group management', type: :feature do

  let!(:ihmi) {create(:organization, name: "IHMI")}

  let!(:protocol_01) {create(:protocol, name: "testProtocol")}
  #created facility group test data
  let!(:group_bathinda) {create(:facility_group, organization: ihmi, name: "Bathinda", protocol: protocol_01)}
  let!(:group_gurdaspur) {create(:facility_group, organization: ihmi, name: "Gurdaspur", protocol: protocol_01)}

  #created facility test data
  let!(:facility_01) {create(:facility, name: "test_facility01", facility_group: group_bathinda)}

  #created unassociated facility test data
  let!(:unassociated_facility) {create(:facility, facility_group: nil, name: "testfacility")}
  let!(:unassociated_facility02) {create(:facility, facility_group: nil, name: "testfacility_02")}

  #created unassigned protocol test data
  let!(:protocol_02) {create(:protocol, name: "testProtocol_02")}

  let!(:org_owner) {
    create(
        :admin,
        :organization_owner,
        admin_access_controls: [AdminAccessControl.new(access_controllable: ihmi)])
  }
  login_page = LoginPage.new
  facility_page = FacilityPage.new
  facility_group = FacilityGroupForm.new

  before(:each) do
    visit root_path
    login_page.do_login(org_owner.email, org_owner.password)
    visit admin_facilities_path
  end

  it "Verify facility landing page" do
    facility_list = [group_bathinda.name, group_gurdaspur.name]
    facility_page.verify_facility_group_landing_page(facility_list)
  end

  it 'create new facility group' do
    facility_page.click_add_facility_group_button
    facility_group.organization_owner_add_new_facility_group('test_facility_group', 'testDescription', unassociated_facility.name, protocol_02.name)
    expect(page).to have_content('test_facility_group')
    expect(page).to have_content(protocol_02.name)
  end

  it "Edit facility group - unassociated facility and protocol " do
    facility_page.click_add_facility_group_button
    facility_group.add_new_facility_group('IHMI', 'test_facility_group', 'testDescription', unassociated_facility.name, protocol_01.name)
    facility_page.click_edit_button_present_for_facility_group("test_facility_group")
    facility_group.is_delete_facility_group_button_present

    #deselect associated facility
    facility_group.click_on_associated_facility(unassociated_facility.name)
    #select new unassigned  facility
    facility_group.select_unassociated_facility(unassociated_facility02.name)
    #updating protocol info
    facility_group.select_protocol_dropdown(protocol_02.name)
    facility_group.click_on_update_facility_group_button
    expect(page).to have_content(unassociated_facility02.name)
    expect(page).to have_content(protocol_02.name)
  end
end