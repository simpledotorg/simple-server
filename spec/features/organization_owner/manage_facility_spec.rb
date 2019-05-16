require 'rails_helper'
require 'Pages/log_in_page'
require 'Pages/facility_page'
require 'Pages/create_update_facility_form_page'
require 'Pages/facility_detail_page'
require 'Pages/edit_users'

RSpec.feature 'MANAGE -Facility Management', type: :feature do

  let!(:test) {create(:organization, name: "Test_org")}
  let!(:protocol_01) {create(:protocol, name: "testProtocol")}
  let!(:group_wardha) {create(:facility_group, organization: test, name: "Wardha", protocol: protocol_01)}
  let!(:facility_02) {create(:facility, name: "test_facility01", facility_group: group_wardha)}

  let!(:org_owner) {
    create(
        :admin,
        :organization_owner,
        admin_access_controls: [AdminAccessControl.new(access_controllable: test)])
  }
  facility_page = FacilityPage.new
  new_facility_page = FacilityFormPage.new
  facility_detail = FacilityDetailPage.new
  edit_user_page = EditUserPage.new

  context "Add and edit facility for any facility group" do
    before(:each) do
      visit root_path
      LoginPage.new.do_login(org_owner.email, org_owner.password)
      visit admin_facilities_path
    end

    it "Add new facility" do
      facility_page.click_add_new_facility
      new_facility_page.verify_new_facility_page
      new_facility_page.create_new_facility("test_name", "PHC", "test_street", "test_village", "test_district", "test_state", "test_country", "123456", "34", "37")
      facility_detail.verify_facility_detail_page
    end
  end
  it "Edit facility " do
    facility_page.click_facility_edit_button

    edit_Facility = FacilityFormPage.new
    edit_Facility.edit_facility("test_name01", "", "", "", "", "", "", "", "", "")

    visit admin_facilities_path
    expect(page).to have_content("test_name01")
  end

  context "Edit facility at facility detail page" do
    before(:each) do
      visit root_path
      LoginPage.new.do_login(org_owner.email, org_owner.password)
      visit admin_facilities_path
      facility_page.click_add_new_facility

      new_facility_page.verify_new_facility_page
      new_facility_page.create_new_facility("test_name", "PHC", "test_street", "test_village", "test_district", "test_state", "test_country", "123456", "34", "37")
      facility_detail.verify_facility_detail_page
    end

    it "reset value" do
      #faiclity detail page
      facility_detail.click_edit_facility_button

      edit_facility_page = FacilityFormPage.new
      edit_facility_page.reset_value
      expect(page).to have_no_content("latitude/longitude")
    end

    it "edit -facility type" do
      facility_detail.click_edit_facility_button

      edit_facility_page = FacilityFormPage.new
      edit_facility_page.edit_facility("", "SC", "", "", "", "", "", "", "", "")
      expect(page).to have_no_content("SC")
    end
  end

  context "Edit user info at detail page" do
    let!(:test_user) {FactoryBot.create_list(:user, 2, facility: facility_02, sync_approval_status: :requested)}
    let!(:facility_03) {create(:facility, name: "test_facility03", facility_group: group_wardha)}

    before(:each) do
      visit root_path
      LoginPage.new.do_login(org_owner.email, org_owner.password)
      visit admin_facilities_path
    end

    it "Edit pin" do
      facility_page.click_on_facility(facility_02.name)
      facility_detail.click_on_edit_button_for_user(test_user.first.full_name)
      edit_user_page.set_pin("2019")
      edit_user_page.set_confirm_pin("2019")
      edit_user_page.click_Update_user_button
      expect(page).to have_no_content("2019")
    end

    it "Edit status-allowed" do
      facility_page.click_on_facility(facility_02.name)
      facility_detail.click_on_edit_button_for_user(test_user.first.full_name)
      edit_user_page.edit_status("allowed")
      expect(page).to have_content("allowed")
      expect(page).to have_content("Deny access")
      expect(page).to have_content("Not logged in yet")
    end

    it "Edit status -denied" do
      facility_page.click_on_facility(facility_02.name)
      facility_detail.click_on_edit_button_for_user(test_user.first.full_name)
      edit_user_page.edit_status("denied")
      expect(page).to have_content("denied")
      expect(page).to have_content("Allow access")
      expect(page).to have_content("Not logged in yet")
    end

    it "Edit -registered facility" do
      facility_page.click_on_facility(facility_02.name)

      user_count = facility_detail.get_total_users_at_facility_detail_page

      facility_detail.click_on_edit_button_for_user(test_user.first.full_name)
      edit_user_page.edit_registration_facility(facility_03.name)
      edit_user_page.click_Update_user_button
      #assertion at user detail page
      expect(page).to have_content(facility_03.name)

      #assertion at facility detail page for facility_02.name
      visit admin_facilities_path
      #select same facility
      facility_page.click_on_facility(facility_02.name)
      expect(facility_detail.get_total_users_at_facility_detail_page).to eq(user_count - 1)

      #assertion at facility detail page facility_03.name
      visit admin_facilities_path
      #select same facility
      facility_page.click_on_facility(facility_03.name)
      expect(page).to have_content(test_user.first.full_name)
    end
  end
end
