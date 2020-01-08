require 'rails_helper'

RSpec.feature 'Invite Admin page functionality', type: :feature do
  let!(:ihmi) {create(:organization, name: "IHMI")}
  let!(:ihmi_group_bathinda) {create(:facility_group, organization: ihmi, name: "Bathinda")}
  let!(:ihmi_group_gurdaspur) {create(:facility_group, organization: ihmi, name: "Gurdaspur")}
  let!(:ihmi_group_hoshiarpur) {create(:facility_group, organization: ihmi, name: "Hoshiarpur")}

  let(:owner) {create(:admin, :owner, organization: ihmi)}

  let!(:path) {create(:organization, name: "PATH")}
  let!(:dr_ayaz) {create(:facility_group, organization: path, name: "Ayaz")}
  let(:path_owner) {create(:admin, :owner, organization: path)}


  admins_page = AdminsPages::Index.new
  admin_show_page = AdminsPages::Show.new
  create_invitation = Email_authentications::Invitation::New.new

  it 'Verify Admin landing page' do
    visit root_path
    sign_in(owner.email_authentication)
    visit admins_path
    expect(page).to have_content('Admins')
    expect(page).to have_content('Add new Admin')
  end

  it 'Invite new admin' do
    visit root_path
    sign_in(owner.email_authentication)
    visit admins_path
    admins_page.click_add_new_Admin_button

    expect(page).to have_content('Send invitation to new Admin')

    create_invitation.fill_in_full_name(Faker::Name.name)
    create_invitation.fill_in_email("test@test.com")
    create_invitation.fill_in_role("cvho")
    create_invitation.select_access_level("Custom")
    create_invitation.select_custom_permission("manage_facilities")
    create_invitation.select_organization("IHMI")
    create_invitation.select_facility("All")
    create_invitation.click_invite_admin_button

    sleep(1000)
    expect(page).to have_content('Admins')
  end

  context "to test error messages- send invite" do
    before(:each) do
      visit root_path
      sign_in(owner.email_authentication)
      visit admins_path
    end

    it "without role" do
      admins_page.click_add_new_Admin_button
      expect(page).to have_content('Send invitation to new Admin')

      create_invitation.fill_in_full_name(Faker::Name.name)
      create_invitation.fill_in_email("test@test.com")
      create_invitation.select_access_level("Custom")
      create_invitation.select_custom_permission("manage_facilities")
      create_invitation.select_organization("IHMI")
      create_invitation.select_facility("All")
      create_invitation.click_invite_admin_button

      #error message assertion
      expect(page).to have_content("Role can't be blank")
    end

    it "without filling any field" do
      admins_page.click_add_new_Admin_button
      expect(page).to have_content('Send invitation to new Admin')
      create_invitation.click_invite_admin_button

      #error message assertion
      expect(page).to have_content("Admin must be assigned at least one permission")
    end

    it "without selecting access level or permission" do
      admins_page.click_add_new_Admin_button
      create_invitation.fill_in_full_name(Faker::Name.name)
      create_invitation.fill_in_email("test@test.com")
      expect(page).to have_content('Send invitation to new Admin')
      create_invitation.select_organization("IHMI")
      create_invitation.select_facility("All")
      create_invitation.click_invite_admin_button

      #error message assertion
      expect(page).to have_content("Admin must be assigned at least one permission")
    end

    it "assign download overdue list permission without view_overdue_list permission" do
      admins_page.click_add_new_Admin_button

      var_email = Faker::Internet::email
      create_invitation.fill_in_full_name(Faker::Name.name)
      create_invitation.fill_in_email(var_email)
      create_invitation.select_access_level("Custom")
      create_invitation.select_custom_permission("download_overdue_list")
      create_invitation.select_organization("IHMI")
      create_invitation.select_facility("All")
      create_invitation.click_invite_admin_button

      #error message assertion
      expect(page).to have_content("Download overdue list requires View overdue list")
    end

    it "assign download_patient_line_list permission without view cohort permission" do
      admins_page.click_add_new_Admin_button

      var_email = Faker::Internet::email
      create_invitation.fill_in_full_name(Faker::Name.name)
      create_invitation.fill_in_email(var_email)
      create_invitation.select_access_level("Custom")
      create_invitation.select_custom_permission("download_patient_line_list")
      create_invitation.select_organization("IHMI")
      create_invitation.select_facility("All")
      create_invitation.click_invite_admin_button

      #error message assertion
      expect(page).to have_content("Download patient line list requires View cohort reports")
    end
  end

  context "edit scenario" do
    it "should retain organization info -IHMI " do
      visit root_path
      sign_in(owner.email_authentication)
      visit admins_path

      admins_page.click_add_new_Admin_button
      expect(page).to have_content('Send invitation to new Admin')

      expect(page).to have_content(ihmi.name)
      expect(page).not_to have_content(path.name)
    end

    it "should retain organization info -PATH" do
      visit root_path
      sign_in(path_owner.email_authentication)
      visit admins_path

      admins_page.click_add_new_Admin_button
      expect(page).to have_content('Send invitation to new Admin')

      expect(page).to have_content(path.name)
      expect(page).not_to have_content(ihmi.name)
    end

    it "should retain assign permission" do
      test = create(:organization, name: "test")
      test_group = create(:facility_group, organization: ihmi, name: "test_group")

      test_facility = create(:facility, facility_group: ihmi_group_bathinda, name: "test_facility")
      test_owner = create(:admin, organization: test)
      permissions = [
          create(:user_permission, user: test_owner, permission_slug: :manage_facilities),
          create(:user_permission, user: test_owner, permission_slug: :manage_facility_groups),
          create(:user_permission, user: test_owner, permission_slug: :manage_admins)
      ]

      visit root_path
      sign_in(test_owner.email_authentication)
      visit admins_path

      admins_page.select_admin_card(test_owner.email)
      permission_list = ["Manage Facilities", "Manage Facility Groups", "Manage Admins"]
      admin_show_page.verify_permission(permission_list)
    end

    it "verify facility-groups,permission,access level in send invite page" do
      test = create(:organization, name: "test")
      test_group = create(:facility_group, organization: ihmi, name: "test_group")

      test_facility = create(:facility, facility_group: ihmi_group_bathinda, name: "test_facility")
      test_owner = create(:admin, organization: test)
      permissions = [
          create(:user_permission, user: test_owner, permission_slug: :manage_facilities),
          create(:user_permission, user: test_owner, permission_slug: :manage_facility_groups),
          create(:user_permission, user: test_owner, permission_slug: :manage_admins)
      ]

      visit root_path
      sign_in(test_owner.email_authentication)
      visit admins_path

      admins_page.click_add_new_Admin_button
    end
  end
end
