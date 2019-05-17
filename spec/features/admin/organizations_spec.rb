require 'rails_helper'

RSpec.feature 'Organization management', type: :feature do
  let!(:owner) {create(:admin, :owner)}
  let!(:ihmi) {create(:organization, name: "IHMI")}
  let!(:path) {create(:organization, name: "PATH")}
  home_page = HomePage.new

  describe "test organization screen" do

    before(:each) do
      visit root_path
      signin(owner)
    end
    it 'Verify organisation is displayed in ManageOrganisation' do
      home_page.select_main_menu_tab("Manage")
      expect(page).to have_content("Organizations")
      expect(page).to have_content("Protocols")

      home_page.select_manage_option('Organizations')
      expect(page).to have_content("IHMI")
      expect(page).to have_content("PATH")
    end

    it 'create organisation ' do
      home_page.select_manage_option("Organizations")
      organization = OrganizationsPage.new
      organization.create_new_organization("test", "testDescription")
    end

    it 'delete organisation ' do
      home_page.select_manage_option("Organizations")
      organization = OrganizationsPage.new
      organization.create_new_organization("test", "testDescription")
      find(:xpath, "//td/a[text() ='test']/../..//td[6]/a").click
      # click_button 'OK'
    end

  end

  it 'Verify owner should be able to delete organisation ' do
    visit root_path
    signin(owner)
    homepage.select_manage_option("Organizations")
    organization = OrganizationsPage.new
    organization.create_new_organization("test", "testDescription")

    find(:xpath, "//td/a[text() ='test']/../..//td[6]/a").click
    # click_button 'OK'
  end
end
