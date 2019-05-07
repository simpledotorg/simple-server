require 'rails_helper'
require 'Pages/log_in_page'
require 'Pages/facility_page'
require 'Pages/new_facility_group_page'


RSpec.feature 'Facility page functionality', type: :feature do
  let(:owner) {create(:admin)}
  let!(:ihmi) {create(:organization, name: "IHMI")}
  let!(:ihmi_group_bathinda) {create(:facility_group, organization: ihmi, name: "Bathinda")}
  let!(:unassociated_facility) {create(:facility, facility_group: nil, name: "testfacility")}
  let!(:unassociated_facility02) {create(:facility, facility_group: nil, name: "testfacility_02")}


  let!(:protocol_01) {create(:protocol,name:"testProtocol")}

  login_page = LoginPage.new
  facility_page = FacilityPage.new
  facility_group=FacilityGroupForm.new

  before(:each) do
    visit root_path
    login_page.do_login(owner.email, owner.password)
    visit admin_facilities_path
  end


  it 'Verify facility landing page ' do
    expect(page).to have_content("All facilities")
    expect(page).to have_content("Facility group")
    expect(page).to have_content('IHMI')
    expect(page).to have_content('Bathinda')

  end

  it 'create new facility group without assigning any facility' do
    facility_page.click_add_facility_group_button

    expect(page).to have_content('New facility group')
    facility_group.add_new_facility_group_without_assigningfacility('IHMI', 'testfacilitygroup', 'testDescription', protocol_01.name)

    expect(page).to have_content('Bathinda')
    expect(page).to have_content('testfacilitygroup')
  end


  it 'create new facility group with facility' do
    facility_page.click_add_facility_group_button

    expect(page).to have_content('New facility group')
    facility_group.add_new_facility_group('IHMI', 'testfacilitygroup','testDescription',unassociated_facility.name, protocol_01.name)

    expect(page).to have_content('Bathinda')
    expect(page).to have_content('testfacilitygroup')
    facility_page.is_edit_button_present_for_facilitygroup('testfacilitygroup')
  end

  it 'owner should be able to delete facility group without facility ' do
    facility_page.click_add_facility_group_button

    expect(page).to have_content('New facility group')
    facility_group.add_new_facility_group('IHMI', 'testfacilitygroup', 'testDescription',unassociated_facility.name, protocol_01.name)

    facility_page.click_edit_button_present_for_facilitygroup("testfacilitygroup")
    expect(page).to have_content('Edit facility group')
    facility_group.is_delete_facilitygroup_button_present
    facility_group.click_on_delete_facilitygroup_button
  end

    it "owner should be able to edit facility group info " do
      facility_page.click_add_facility_group_button

      facility_group.add_new_facility_group('IHMI', 'testfacilitygroup', 'testDescription',unassociated_facility.name, protocol_01.name)

      facility_page.click_edit_button_present_for_facilitygroup("testfacilitygroup")

      #deselecting previously selected facility
      facility_group.select_unassociated_facility(unassociated_facility.name)

      #select new unassigned  facility
      facility_group.select_unassociated_facility(unassociated_facility02.name)
      facility_group.click_on_update_facility_group_button

      expect(page).to have_content(unassociated_facility02.name)
    end


end
