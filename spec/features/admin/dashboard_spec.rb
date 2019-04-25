require 'rails_helper'
require 'Pages/dashboard_page'
require 'Pages/logIn_page'
require 'Pages/home_page'
require 'Pages/organizations_page'

describe 'test dashboard' do


  let(:owner) {create(:admin, role: :owner)}
  let!(:ihmi) {create(:organization, name: "IHMI")}
  let!(:path) {create(:organization, name: "PATH")}

  dashboard = DashboardPage.new
  login = LoginPage.new
  homepage = HomePage.new

  describe 'organisation Names' do

    it 'Verify organisation is displayed in dashboard' do
      visit root_path
      login.doLogin(owner.email, owner.password)

      #asssertion
      expect(dashboard.getOrganisaitonCount).to eq(2)
      expect(page).to have_content("IHMI")
      expect(page).to have_content("PATH")
    end


    it 'Verify organisation is displayed in ManageOrganisation' do
      visit root_path
      login.doLogin(owner.email, owner.password)

      homepage.selectMainMenuTab("Manage")
      expect(page).to have_content("Organizations")
      expect(page).to have_content("Protocols")

      homepage.selectManageOption('Organizations')
      expect(page).to have_content("IHMI")
      expect(page).to have_content("PATH")

    end

    it 'Verify organisation name/count get updated in dashboard when new org is added via manage section' do

      visit root_path

      login.doLogin(owner.email, owner.password)
      #total number of organizaiton present in dashborad
      organisaiton_count = dashboard.getOrganisaitonCount


      homepage.selectManageOption("Organizations")
      organization = OrganisaitonsPage.new
      organization.createNewOrganisation

      #assertion at organization screen
      expect(page).to have_content('Organization was successfully created.')
      organization.verifyOrganisationInfo

      homepage.selectMainMenuTab("Dashboard")
      #assertion at dashboard screen
      expect(page).to have_content("test")
      expect(dashboard.getOrganisaitonCount).to eq(organisaiton_count + 1)

    end
  end

  describe "Create a User and then  Sign in and  verify approval request " do
    #creating a user

    it 'SignIn as Owner and verify approval request in dashboard' do
      user = create(:user, sync_approval_status: :requested)
      visit root_path
      login.doLogin(owner.email, owner.password)

      expect(page).to have_content("Allow access")
      expect(page).to have_content("Deny access")
      #check for user info
      expect(page).to have_content(user.full_name)
      expect(page).to have_content(user.phone_number)
    end
  end

  it 'Verify owner should be ab le to delete organisation ' do


    visit root_path

    login.doLogin(owner.email, owner.password)

    homepage.selectManageOption("Organizations")
    organization = OrganisaitonsPage.new
    organization.createNewOrganisation


    find(:xpath, "//td/a[text() ='test']/../..//td[6]/a").click
    # page.accept_alert
    # expect(page).to have_content("Organization was successfully deleted.")

  end
end