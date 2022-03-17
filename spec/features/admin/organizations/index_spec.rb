require "features_helper"

RSpec.feature "Organization management", type: :feature do
  let!(:owner) { create(:admin, :power_user) }
  let!(:ihmi) { create(:organization, name: "IHMI") }
  let!(:path) { create(:organization, name: "PATH") }
  let!(:facility) { create(:facility) }

  login = AdminPage::Sessions::New.new
  organization_page = AdminPage::Organizations::Index.new

  describe "test organization screen" do
    it "Verify organisation is displayed in ManageOrganisation" do
      visit admin_organizations_path
      login.do_login(owner.email, owner.password)

      expect(page).to have_content("IHMI")
      expect(page).to have_content("PATH")
    end

    it "Verify owner should be able to delete organisation " do
      visit admin_organizations_path
      login.do_login(owner.email, owner.password)

      organization_page.click_on_add_organization_button

      AdminPage::Organizations::New.new.create_new_organization("test", "testDescription")
      organization_page.delete_organization("Test")
    end
  end
end
