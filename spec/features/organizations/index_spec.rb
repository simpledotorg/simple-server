require "rails_helper"

RSpec.feature "Verify Dashboard", type: :feature do
  let!(:ihmi) { create(:organization, name: "IHMI") }
  let!(:path) { create(:organization, name: "PATH") }
  let!(:facility_group) { create(:facility_group, organization: ihmi) }
  let!(:facility) { create(:facility, facility_group: facility_group) }
  let!(:owner) { create(:admin, :power_user) }

  login_page = AdminPage::Sessions::New.new
  dashboard = OrganizationsPage::Index.new
  dashboard_navigation = Navigations::DashboardPageNavigation.new
  org_page = AdminPage::Organizations::Index.new

  before { enable_flag(:new_permissions_system_aug_2020, owner) }
  after { disable_flag(:new_permissions_system_aug_2020, owner) }

  xit "Verify organization is displayed in dashboard" do
    visit root_path
    login_page.do_login(owner.email, owner.password)

    # assertion
    expect(dashboard.get_organization_count).to eq(2)
    expect(page).to have_content("IHMI")
    expect(page).to have_content("PATH")
  end

  it "Verify organisation name/count get updated in dashboard when new org is added via manage section" do
    visit root_path
    login_page.do_login(owner.email, owner.password)

    # total number of organization present in dashboard
    visit organizations_path
    var_organization_count = dashboard.get_organization_count

    dashboard_navigation.select_manage_option("Organizations")

    org_page.click_on_add_organization_button
    AdminPage::Organizations::New.new.create_new_organization("test", "testDescription")

    # assertion at organization screen
    expect(page).to have_content("Organization was successfully created.")
    org_page.is_organization_name_present("Test")

    # Dashboard doesn't show Organizations without any facilities
    fg = create(:facility_group, organization: Organization.find_by_name("Test"))
    create(:facility, facility_group: fg)

    dashboard_navigation.select_main_menu_tab("Old Reports")

    # assertion at dashboard screen
    expect(page).to have_content("Test")
    expect(dashboard.get_organization_count).to eq(var_organization_count + 1)
  end

  it "SignIn as Owner and verify approval request in dashboard" do
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
end
