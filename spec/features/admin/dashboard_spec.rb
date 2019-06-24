require 'rails_helper'

RSpec.feature 'Verify Dashboard', type: :feature do
  let(:email) { Faker::Internet.email }
  let(:password) { Faker::Internet.password }

  let!(:ihmi) { create(:organization, name: "IHMI") }
  let!(:path) { create(:organization, name: "PATH") }

  before :each do
    create(:user, :with_email_authentication,
           email: email,
           password: password,
           permissions: [:can_manage_all_organizations])
  end

  login_page = LoginPage.new
  dashboard = DashboardPage.new
  home_page = HomePage.new

  it 'Verify organization is displayed in dashboard' do
    visit root_path
    login_page.do_login(email, password)
    #asssertion
    expect(dashboard.get_organization_count).to eq(2)
    expect(page).to have_content("IHMI")
    expect(page).to have_content("PATH")
  end

  it 'Verify organisation name/count get updated in dashboard when new org is added via manage section' do

    visit root_path
    login_page.do_login(email, password)
    #total number of organizaiton present in dashborad
    organization_count = dashboard.get_organization_count

    home_page.select_manage_option("Organizations")
    organization = OrganizationsPage.new
    organization.create_new_organization("test", "testDescription")

    #assertion at organization screen
    expect(page).to have_content('Organization was successfully created.')
    organization.verify_organization_info

    home_page.select_main_menu_tab("Dashboard")
    #assertion at dashboard screen
    expect(page).to have_content("test")
    expect(dashboard.get_organization_count).to eq(organization_count + 1)
  end

  it 'SignIn as Owner and verify approval request in dashboard' do
    user = create(:user, sync_approval_status: :requested)
    visit root_path
    login_page.do_login(email, password)

    expect(page).to have_content("Allow access")
    expect(page).to have_content("Deny access")
    #check for user info
    expect(page).to have_content(user.full_name)
    expect(page).to have_content(user.phone_number)
  end
end
