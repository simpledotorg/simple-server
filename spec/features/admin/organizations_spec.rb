require 'rails_helper'

RSpec.feature 'Organization management', type: :feature do
  let(:email) { Faker::Internet.email }
  let(:password) { Faker::Internet.password }

  let!(:ihmi) { create(:organization, name: "IHMI") }
  let!(:path) { create(:organization, name: "PATH") }
  login = LoginPage.new
  homepage = HomePage.new

  before :each do
    create(:user, :with_email_authentication,
           email: email,
           password: password,
           permissions: [:can_manage_all_organizations, :can_manage_all_protocols])
  end

  describe "test organization screen" do
    it 'Verify organisation is displayed in ManageOrganisation' do
      visit root_path
      login.do_login(email, password)

      homepage.select_main_menu_tab("Manage")
      expect(page).to have_content("Organizations")
      expect(page).to have_content("Protocols")

      homepage.select_manage_option('Organizations')
      expect(page).to have_content("IHMI")
      expect(page).to have_content("PATH")
    end

    it 'Verify owner should be able to delete organisation ' do
      visit root_path
      login.do_login(email, password)

      homepage.select_manage_option("Organizations")
      organization = OrganizationsPage.new
      organization.create_new_organization("test", "testDescription")

      find(:xpath, "//td/a[text() ='test']/../..//td[6]/a").click
      # click_button 'OK'
    end
  end
end
