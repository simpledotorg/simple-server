require "rails_helper"

RSpec.feature "Organization management", type: :feature do
  let!(:owner) { create(:admin, :power_user) }
  let!(:ihmi) { create(:organization, name: "IHMI") }
  let!(:path) { create(:organization, name: "PATH") }
  let!(:facility) { create(:facility) }

  login = AdminPage::Sessions::New.new
  dashboard_navigation = Navigations::DashboardPageNavigation.new
  organization_page = AdminPage::Organizations::Index.new

  describe "test organization screen" do
    before { Flipper.enable(:new_permissions_system_aug_2020) }
    after { Flipper.disable(:new_permissions_system_aug_2020) }

    it "Verify organisation is displayed in ManageOrganisation" do
      visit root_path
      login.do_login(owner.email, owner.password)

      find("#nav-more-link").click
      find("#nav-organizations-link").click
      expect(page).to have_content("IHMI")
      expect(page).to have_content("PATH")
    end

    it "Verify owner should be able to delete organisation " do
      visit root_path
      login.do_login(owner.email, owner.password)

      find("#nav-more-link").click
      find("#nav-organizations-link").click
      organization_page.click_on_add_organization_button

      AdminPage::Organizations::New.new.create_new_organization("test", "testDescription")
      organization_page.delete_organization("Test")
    end
  end
end
