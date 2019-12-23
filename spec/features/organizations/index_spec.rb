require 'rails_helper'

RSpec.feature 'Verify Dashboard', type: :feature do
  let!(:ihmi) { create(:organization, name: "IHMI") }
  let!(:path) { create(:organization, name: "PATH") }
  let!(:owner) { create(:admin) }
  let!(:permissions) { [
    create(:user_permission, user: owner, permission_slug: :view_cohort_reports),
    create(:user_permission, user: owner, permission_slug: :approve_health_workers),
    create(:user_permission, user: owner, permission_slug: :manage_organizations)
  ]}

  login_page = AdminPage::Sessions::New.new
  dashboard = OrganizationsPage::Index.new
  dashboard_navigation = Navigations::DashboardPageNavigation.new
  org_page = AdminPage::Organizations::Index.new


  xit 'Verify organization is displayed in dashboard' do
    visit root_path
    login_page.do_login(owner.email, owner.password)

    # assertion
    expect(dashboard.get_organization_count).to eq(2)
    expect(page).to have_content("IHMI")
    expect(page).to have_content("PATH")
  end

  it 'Verify organisation name/count get updated in dashboard when new org is added via manage section' do
    visit root_path
    login_page.do_login(owner.email, owner.password)

    # total number of organization present in dashboard
    var_organization_count = dashboard.get_organization_count

    dashboard_navigation.select_manage_option("Organizations")

    org_page.click_on_add_organization_button
    AdminPage::Organizations::New.new.create_new_organization("test", "testDescription")

    # assertion at organization screen
    expect(page).to have_content('Organization was successfully created.')
    org_page.is_organization_name_present("test")

    dashboard_navigation.select_main_menu_tab("Dashboard")

    # assertion at dashboard screen
    expect(page).to have_content("test")
    expect(dashboard.get_organization_count).to eq(var_organization_count + 1)
  end

  it 'SignIn as Owner and verify approval request in dashboard' do
    user = create(:user, :with_phone_number_authentication)
    user.sync_approval_status = User.sync_approval_statuses[:requested]
    user.save!

    visit root_path
    login_page.do_login(owner.email, owner.password)

    expect(page).to have_content("Allow access")
    expect(page).to have_selector("i.fa-times")

    # check for user info
    expect(page).to have_content(user.full_name)
    expect(page).to have_content(user.phone_number)
  end

  it "verify manage section overlay for given permission" do
    visit root_path
    login_page.do_login(owner.email, owner.password)
    expect(page).to have_content("Dashboard")

    dashboard_navigation.select_main_menu_tab("Manage")

    expect(page).to have_content("Users")
    expect(page).to have_content("Organizations")

    headings = ['Admins','Protocols', 'Facilities']
    headings.each do |heading|
      expect(page).not_to have_content(heading)
    end
  end

end
