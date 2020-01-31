# frozen_string_literal: true
require 'rails_helper'

RSpec.feature 'Facility page functionality', type: :feature do
  let(:admin) { create(:admin) }

  let!(:ihmi) { create(:organization, name: 'IHMI') }
  let!(:another_organization) { create(:organization) }
  let!(:ihmi_group_bathinda) { create(:facility_group, organization: ihmi, name: 'Bathinda') }
  let!(:unassociated_facility) { create(:facility, facility_group: nil, name: 'testfacility') }
  let!(:unassociated_facility02) { create(:facility, facility_group: nil, name: 'testfacility_02') }

  let!(:protocol_01) { create(:protocol, name: 'testProtocol') }

  facility_page = AdminPage::Facilities::Index.new
  facility_group = AdminPage::FacilityGroups::New.new
  navigation = Navigations::DashboardPageNavigation.new


  context 'facility group listing' do
    context 'admin has permission to manage facility groups' do
      let!(:permissions) do
        [create(:user_permission, user: admin, permission_slug: :manage_facility_groups)]
      end

      before do
        visit root_path
        sign_in(admin.email_authentication)
        visit admin_facilities_path
      end

      it 'Verify facility landing page' do
        facility_page.verify_facility_page_header
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
        facility_group.add_new_facility_group('IHMI', 'testfacilitygroup', 'testDescription', unassociated_facility.name, protocol_01.name)

        expect(page).to have_content('Bathinda')
        expect(page).to have_content('testfacilitygroup')
        facility_page.is_edit_button_present_for_facilitygroup('testfacilitygroup')
      end

      it 'admin should be able to delete facility group without facility ' do
        facility_page.click_edit_button_present_for_facilitygroup(ihmi_group_bathinda.name)
        expect(page).to have_content('Edit facility group')
        facility_group.click_on_delete_facility_group_button
      end

      it 'admin should be able to edit facility group info ' do
        facility_page.click_add_facility_group_button
        facility_group.add_new_facility_group('IHMI', 'testfacilitygroup', 'testDescription', unassociated_facility.name, protocol_01.name)
        facility_page.click_edit_button_present_for_facilitygroup('testfacilitygroup')

        # deselecting previously selected facility
        facility_group.select_unassociated_facility(unassociated_facility.name)

        # select new unassigned facility
        facility_group.select_unassociated_facility(unassociated_facility02.name)
        facility_group.click_on_update_facility_group_button

        expect(page).to have_content(unassociated_facility02.name)
      end

      it 'renders only allowed tabs for the given permissions' do
        navigation.select_main_menu_tab('Manage')

        expect(page).to have_content('Facilities')

        headings = ['Admins', 'Protocols', 'Users']
        headings.each do |heading|
          expect(page).not_to have_content(heading)
        end
      end
    end
  end

  context 'facility listing' do
    context 'admin  has permission to manage facilities for a facility group' do
      let!(:permissions) do
        [create(:user_permission, user: admin, permission_slug: :manage_facilities, resource: ihmi_group_bathinda)]
      end

      before(:each) do
        visit root_path
        sign_in(admin.email_authentication)
        visit admin_facilities_path
      end

      it 'displays a new facility link' do
        expect(page).to have_link('New Facility', href: new_admin_facility_group_facility_path(ihmi_group_bathinda))
      end
    end

    context 'admin does not have permission to manage facilities a facility group' do
      let!(:permissions) do
        [create(:user_permission, user: admin, permission_slug: :manage_facilities, resource: create(:facility_group))]
      end

      before(:each) do
        visit root_path
        sign_in(admin.email_authentication)
        visit admin_facilities_path
      end

      it 'does not display a new facility link' do
        expect(page).not_to have_link('New Facility', href: new_admin_facility_group_facility_path(ihmi_group_bathinda))
      end
    end
  end
end
