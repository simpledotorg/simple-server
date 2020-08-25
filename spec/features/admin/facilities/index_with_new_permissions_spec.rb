# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Facility page functionality with new permissions", type: :feature do
  let!(:ihmi) { create(:organization, name: "IHMI") }
  let!(:another_organization) { create(:organization) }
  let!(:ihmi_group_bathinda) { create(:facility_group, organization: ihmi, name: "Bathinda") }
  let!(:unassociated_facility) { create(:facility, facility_group: nil, name: "testfacility") }
  let!(:unassociated_facility02) { create(:facility, facility_group: nil, name: "testfacility_02") }

  let!(:protocol_01) { create(:protocol, name: "testProtocol") }

  facility_page = AdminPage::Facilities::Show.new
  facility_group = AdminPage::FacilityGroups::New.new

  context "facility group listing" do
    context "admin has permission to manage facility groups" do
      let(:admin) { create(:admin, :power_user) }
      let!(:permissions) do
        [create(:user_permission, user: admin, permission_slug: :manage_facility_groups)]
      end

      before(:each) do
        with_flag_enabled(:new_permissions_system_aug_2020, admin) {
          visit root_path
          sign_in(admin.email_authentication)
          visit admin_facilities_path
        }
      end

      it "Verify facility landing page" do
        facility_page.verify_facility_page_header
        expect(page).to have_content("IHMI")
        expect(page).to have_content("Bathinda")
      end

      it "create new facility group without assigning any facility" do
        facility_page.click_add_facility_group_button

        expect(page).to have_content("New facility group")
        facility_group.add_new_facility_group_without_assigningfacility("IHMI", "testfacilitygroup", "testDescription", protocol_01.name)

        expect(page).to have_content("Bathinda")
        expect(page).to have_content("Testfacilitygroup")
      end

      it "create new facility group with facility" do
        facility_page.click_add_facility_group_button

        expect(page).to have_content("New facility group")
        facility_group.add_new_facility_group("IHMI", "testfacilitygroup", "testDescription", unassociated_facility.name, protocol_01.name)

        expect(page).to have_content("Bathinda")
        expect(page).to have_content("Testfacilitygroup")
        facility_page.is_edit_button_present_for_facilitygroup("Testfacilitygroup")
      end

      it "admin should be able to delete facility group without facility " do
        facility_page.click_edit_button_present_for_facilitygroup(ihmi_group_bathinda.name)
        expect(page).to have_content("Edit facility group")
        facility_group.click_on_delete_facility_group_button
      end

      it "admin should be able to edit facility group info " do
        facility_page.click_add_facility_group_button
        facility_group.add_new_facility_group("IHMI", "testfacilitygroup", "testDescription", unassociated_facility.name, protocol_01.name)
        facility_page.click_edit_button_present_for_facilitygroup("Testfacilitygroup")

        # deselecting previously selected facility
        facility_group.select_unassociated_facility(unassociated_facility.name)

        # select new unassigned facility
        facility_group.select_unassociated_facility(unassociated_facility02.name)
        facility_group.click_on_update_facility_group_button

        expect(page).to have_content(unassociated_facility02.name)
      end
    end
  end

  context "facility listing" do
    context "admin has permission to manage facilities for a facility group" do
      let(:admin) { create(:admin, :manager, accesses: [build(:access, resource: ihmi_group_bathinda)]) }
      let!(:permissions) do
        [create(:user_permission, user: admin, permission_slug: :manage_facilities, resource: ihmi_group_bathinda)]
      end

      before(:each) do
        with_flag_enabled(:new_permissions_system_aug_2020, admin) {
          visit root_path
          sign_in(admin.email_authentication)
          visit admin_facilities_path
        }
      end

      it "Verify facility landing page" do
        facility_page.verify_facility_page_header
        expect(page).not_to have_content("IHMI")
        expect(page).to have_content("Bathinda")
      end

      it "displays a new facility link" do
        expect(page).to have_link("Add a facility", href: new_admin_facility_group_facility_path(ihmi_group_bathinda))
      end
    end

    context "admin does not have permission to manage facilities a facility group" do
      let(:admin) { create(:admin, :manager, accesses: [build(:access, resource: create(:facility_group))]) }
      let!(:permissions) do
        [create(:user_permission, user: admin, permission_slug: :manage_facilities, resource: create(:facility_group))]
      end

      before(:each) do
        with_flag_enabled(:new_permissions_system_aug_2020, admin) {
          visit root_path
          sign_in(admin.email_authentication)
          visit admin_facilities_path
        }
      end

      it "does not display a new facility link" do
        expect(page).not_to have_link("Add a facility", href: new_admin_facility_group_facility_path(ihmi_group_bathinda))
      end
    end
  end
end
