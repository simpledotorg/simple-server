require 'rails_helper'
require 'Pages/log_in_page'
require 'Pages/users_page'
require 'Pages/edit_users'
require 'Pages/users_registered_facility_detail_page'
require 'Pages/user_detail_page'
require 'Pages/facility_page'

RSpec.feature 'Manage Section: User Management', type: :feature do

  let!(:ihmi) {create(:organization, name: "IHMI")}
  let!(:org_owner) {
    create(
        :admin,
        :organization_owner,
        admin_access_controls: [AdminAccessControl.new(access_controllable: ihmi)])
  }
  users_page = UsersPage.new
  edit_user_page = EditUserPage.new
  user_detail_page = UserDetailsPage.new
  facility_page = FacilityPage.new


  context "check" do
    let!(:protocol_01) {create(:protocol, name: "testProtocol")}
    let!(:group_wardha) {create(:facility_group, organization: ihmi, name: "Wardha", protocol: protocol_01)}
    let!(:group_bathinda) {create(:facility_group, organization: ihmi, name: "bathinda", protocol: protocol_01)}

    let!(:facility_03) {create(:facility, name: "test_facility03", facility_group: group_wardha)}
    let!(:facility_04) {create(:facility, name: "test_facility04", facility_group: group_bathinda)}

    let!(:test_user) {create_list(:user, 1, sync_approval_status: :requested, facility: facility_03)}
    let!(:test_user1) {create_list(:user, 2, sync_approval_status: :requested, facility: facility_04)}

    it "should be able to view all users" do
      visit root_path
      signin(org_owner)
      visit admin_users_path
      expect(users_page.get_district_count).to eq(2)
      expect(users_page.get_users_count).to eq(4)
    end

    context "Edit user info" do

      before(:each) do
        visit root_path
        signin(org_owner)
        visit admin_users_path
      end

      it "Edit pin" do
        users_page.click_edit_link(test_user.first.full_name)
        edit_user_page.set_pin("2019")
        edit_user_page.set_confirm_pin("2019")
        edit_user_page.click_Update_user_button
        expect(page).to have_no_content("2019")
      end

      it "Edit status-allowed" do
        users_page.click_edit_link(test_user.first.full_name)
        edit_user_page.edit_status("allowed")
        expect(page).to have_content("allowed")
        expect(page).to have_content("Deny access")
        expect(page).to have_content("Not logged in yet")
      end

      it "Edit status -denied" do
        users_page.click_edit_link(test_user1.first.full_name)
        edit_user_page.edit_status("denied")
        expect(page).to have_content("denied")
        expect(page).to have_content("Allow access")
        expect(page).to have_content("Not logged in yet")
      end

      it "Edit -registered facility" do
        users_page.click_edit_link(test_user1.first.full_name)
        # user_count =

        edit_user_page.edit_registration_facility(facility_03.name)
        edit_user_page.click_Update_user_button
        #assertion at user detail page
        expect(page).to have_content(facility_03.name)

        #assertion at User page
        visit admin_users_path
        # expect(facility_detail.get_total_users_at_facility_detail_page).to eq(user_count - 1)

        #assertion at facility detail page facility_03.name
        visit admin_facilities_path
        #select same facility
        facility_page.click_on_facility(facility_03.name)
        expect(page).to have_content(test_user.first.full_name)
      end

      it "verify user detail page" do
        users_page.select_user(test_user.first.full_name)
        user_detail_page.verify_user_detail_page
      end

      it "edit user pin- User detail page " do
        users_page.select_user(test_user.first.full_name)
        user_detail_page.verify_user_detail_page
        user_detail_page.click_on_edit_link
        edit_user_page.set_pin("2019")
        edit_user_page.click_Update_user_button
        expect(page).to have_no_content("2019")
      end

      it "edit user registration facility- User detail page " do
        users_page.select_user(test_user.first.full_name)
        user_detail_page.verify_user_detail_page
        user_detail_page.click_on_edit_link
        edit_user_page.edit_registration_facility(facility_04.name)
        edit_user_page.click_Update_user_button
        expect(page).to have_content(facility_04.name)
      end
    end
  end
end