require 'rails_helper'

RSpec.feature 'Organization management', type: :feature do
  let!(:owner) { create(:admin) }
  let!(:permissions) { create(:user_permission, user: owner, permission_slug: :manage_organizations) }
  let!(:ihmi) { create(:organization, name: 'IHMI') }
  let!(:path) { create(:organization, name: 'PATH') }

  login                = AdminPage::Sessions::New.new
  dashboard_navigation = Navigations::DashboardPageNavigation.new
  organization_page    = AdminPage::Organizations::Index.new

  describe "test organization screen" do
    before do
      visit root_path
      login.do_login(owner.email, owner.password)
    end

    it 'Verify organisation is displayed in ManageOrganisation' do
      dashboard_navigation.select_manage_option('Organizations')
      expect(page).to have_content('IHMI')
      expect(page).to have_content('PATH')
    end

    it 'Verify owner should be able to delete organisation ' do
      dashboard_navigation.select_manage_option('Organizations')
      organization_page.click_on_add_organization_button

      AdminPage::Organizations::New.new.create_new_organization("test", "testDescription")
      organization_page.delete_organization('test')
    end

    it "renders only allowed tabs for the given permissions" do
      dashboard_navigation.select_main_menu_tab('Manage')

      expect(page).to have_content('Organizations')

      headings = ['Admins', 'Protocols', 'Users', 'Facilities']
      headings.each do |heading|
        expect(page).not_to have_content(heading)
      end
    end
  end
end
