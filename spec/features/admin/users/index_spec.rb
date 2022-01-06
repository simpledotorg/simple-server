# frozen_string_literal: true

require "features_helper"

RSpec.feature "Admin User page functionality", type: :feature do
  let(:owner) { create(:admin, :power_user) }
  let!(:ihmi) { create(:organization, name: "IHMI") }
  let!(:path) { create(:organization, name: "PATH") }
  let!(:group_bathinda) { create(:facility_group, organization: ihmi, name: "Bathinda") }
  let!(:facility_hoshiarpur) { create(:facility, facility_group: group_bathinda, name: "Hoshiarpur", district: "Hoshiarpur") }
  let!(:facility_buchho) { create(:facility, facility_group: group_bathinda, name: "Buchho", district: "Buchho") }

  let!(:group_Bangalore) { create(:facility_group, organization: path, name: "Bangalore") }
  let!(:facility_nilenso) { create(:facility, facility_group: group_Bangalore, name: "Nilenso", district: "Nilenso") }
  let!(:facility_obvious) { create(:facility, facility_group: group_Bangalore, name: "Obvious", district: "Obvious") }
  let!(:a_user) { create(:user, :with_phone_number_authentication, registration_facility: facility_obvious) }
  user_page = AdminPage::Users::Index.new
  login_page = AdminPage::Sessions::New.new
  navigation = Navigations::DashboardPageNavigation.new

  context "Admin User landing page" do
    before(:each) do
      visit reports_regions_path
      login_page.do_login(owner.email, owner.password)
      navigation.click_manage_option("#mobile-app-users")
    end

    it "Verify User landing page" do
      user_page.verify_user_landing_page
    end

    it "verify all district should be displayed in alphabetical order in facility dropdown" do
      var_list = ["All districts", facility_hoshiarpur.name, facility_buchho.name, facility_nilenso.name, facility_obvious.name]
      user_page.click_on_district_dropdown
      actual_array = user_page.get_all_districts_name
      expect(actual_array).to match_array(var_list.sort)
    end
  end

  context " javascript based test", js: true do
    let(:owner) { create(:admin, :power_user) }
    let!(:ihmi) { create(:organization, name: "IHMI") }
    let!(:group_bathinda) { create(:facility_group, organization: ihmi, name: "Bathinda") }
    let!(:facility_hoshiarpur) { create(:facility, facility_group: group_bathinda, name: "Hoshiarpur", district: "Hoshiarpur") }
    let!(:facility_buchho) { create(:facility, facility_group: group_bathinda, name: "Buchho", district: "Buchho") }

    let!(:path) { create(:organization, name: "PATH") }
    let!(:var_path_facility_group) { create(:facility_group, organization: path, name: "Dr Amir") }
    let!(:var_amir) { create(:facility, facility_group: var_path_facility_group, name: "Dr Amir Sen", district: "dharavi") }

    user_page = AdminPage::Users::Index.new
    login_page = AdminPage::Sessions::New.new
    navigation = Navigations::DashboardPageNavigation.new
    edit_page = AdminPage::Users::Edit.new

    it " should display user list for - different district for IHMI" do
      create_list(:user, 5, registration_facility: facility_hoshiarpur)
      create_list(:user, 4, registration_facility: facility_buchho)

      visit root_path
      login_page.do_login(owner.email, owner.password)
      navigation.click_manage_option("#mobile-app-users")

      user_page.select_district("All districts")
      expect(user_page.get_all_user_count).to eq(10)

      user_page.select_district(facility_hoshiarpur.district)
      user_page.is_facility_name_present(facility_hoshiarpur.name)
      expect(user_page.get_all_user(facility_hoshiarpur.district)).to eq(5)

      user_page.select_district(facility_buchho.district)
      user_page.is_facility_name_present(facility_buchho.name)
      expect(user_page.get_all_user(facility_buchho.district)).to eq(4)
    end

    it " should be able to edit User facility" do
      user = create_list(:user, 5, registration_facility: facility_buchho)

      visit root_path
      login_page.do_login(owner.email, owner.password)
      navigation.click_manage_option("#mobile-app-users")

      user_page.select_district(facility_buchho.district)
      # assertion for chc buchoo facility
      expect(user_page.get_all_user(facility_buchho.name)).to eq(5)

      # edit facility to hoshiarpur  for a nth user(last) in chc buchho
      user_page.click_edit_button(user.last.full_name)
      edit_page.edit_registration_facility(facility_hoshiarpur.name)

      # user should be displayed in hoshiarpur as we have edited its registration facility
      navigation.click_manage_option("#mobile-app-users")
      user_page.select_district(facility_hoshiarpur.district)
      expect(user_page.get_all_user(facility_hoshiarpur.name)).to eq(1)

      # select chc buchho and verify total user count should get reduced by 1
      user_page.select_district(facility_buchho.district)
      expect(user_page.get_all_user(facility_buchho.name)).to eq(4)
    end

    it " should display user list for - Path Dr Amir Sen" do
      create_list(:user, 5, registration_facility: var_amir)

      visit root_path
      login_page.do_login(owner.email, owner.password)
      navigation.click_manage_option("#mobile-app-users")

      user_page.select_district(var_amir.district)
      user_page.is_facility_name_present(var_amir.name)
      expect(user_page.get_all_user(var_amir.name)).to eq(5)
    end
  end

  context "admin should be able to allow/Deny User access  " do
    let(:owner) { create(:admin, :power_user) }
    let!(:facility_hoshiarpur) { create(:facility, name: "Hoshiarpur") }
    let!(:facility_Buchoo) { create(:facility, name: "CHC Buchho") }

    user_page = AdminPage::Users::Index.new
    login_page = AdminPage::Sessions::New.new
    navigation = Navigations::DashboardPageNavigation.new

    it "deny user access" do
      user = create(:user)
      user.sync_approval_status = User.sync_approval_statuses[:requested]
      user.save

      visit root_path
      login_page.do_login(owner.email, owner.password)
      navigation.click_manage_option("#mobile-app-users")
      user_page.deny_access(user.full_name)
    end

    it "allow access" do
      user = create(:user)
      user.sync_approval_status = User.sync_approval_statuses[:requested]
      user.save

      visit root_path
      login_page.do_login(owner.email, owner.password)
      navigation.click_manage_option("#mobile-app-users")
      user_page.allow_access(user.full_name)
    end

    it "allow access for user with denied access" do
      user = create(:user)
      user.sync_approval_status = User.sync_approval_statuses[:denied]
      user.save

      visit root_path
      login_page.do_login(owner.email, owner.password)
      navigation.click_manage_option("#mobile-app-users")
      user_page.allow_access(user.full_name)
    end
  end
end
