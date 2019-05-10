require 'rails_helper'
require 'Pages/log_in_page'
require 'Pages/users_page'
require 'Pages/edit_users'
require 'Pages/users_registered_facility_detail_page'

RSpec.feature 'Users Management ', type: :feature do

  let(:owner) {create(:admin, :owner)}
  login_page = LoginPage.new
  users_page = UsersPage.new
  edit_user_page = EditUserPage.new
  registered_faciltiy_page = UsersRegisteredFacilityPage.new

  describe "owner-Manage Users Section" do


    context "edit info for single user" do
      @user = create(:user, sync_approval_status: :requested)

      before(:each) do
        visit root_path
        login_page.do_login(owner.email, owner.password)
        visit admin_users_path
      end

      it 'verify Users landing page' do
        users_page.verify_users_landing_page
        expect(users_page.all_district.size).to eq(1)
        expect(page).to have_content(@user.full_name)
        expect(page).to have_content(@user.phone_number)
        expect(page).to have_content("Requested")
      end

      it 'Edit users -phone num and pin' do
        users_page.click_edit_link(user.full_name)
        edit_user_page.verify_Edit_user_landing_page
        edit_user_page.set_phone_number("01234567876")
        edit_user_page.set_pin("2019")
        edit_user_page.set_confirm_pin("2019")

        #assertion at user detail page
        expect(page).to have_content("012345678877")
        expect(page).to have_no_content("2019")

        #assertion at Users landing page
        visit admin_users_path
        expect(page).to have_content("012345678877")
        expect(page).to have_no_content("2019")
      end

      # will try to data drive for denied
      it 'Edit user - status' do
        #assertion at dashboard
        expect(page).to have_content("Allow access")
        expect(page).to have_content("Deny access")


        visit admin_users_path
        users_page.click_edit_link(user.full_name)
        edit_user_page.edit_status("allowed")
        print page.html

        #assertion at user detail page
        expect(page).to have_content("allowed")

        #assertion at Users landing page
        visit admin_users_path
        expect(page).to have_content("Allowed")
      end

      it "verify registered facility link" do
        users_page.click_registered_facility_link(user.full_name)
        registered_faciltiy_page.verify_registered_facility_landing_page
      end
    end

    it "should be able to view all users" do
      FactoryBot.create_list(:user, 5, sync_approval_status: :requested)
      visit root_path
      login_page.do_login(owner.email, owner.password)
      visit admin_users_path
      print page.html
      expect(users_page.all_district.size).to eq(1)
      expect(users_page.all_user.size).to eq(5)
    end
  end
end
