# frozen_string_literal: true

require "features_helper"

RSpec.feature "Verify Dashboard", type: :feature do
  let!(:ihmi) { create(:organization, name: "IHMI") }
  let!(:path) { create(:organization, name: "PATH") }
  let!(:facility_group_1) { create(:facility_group, organization: ihmi) }
  let!(:facility_group_2) { create(:facility_group, organization: path) }
  let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
  let!(:facility_2) { create(:facility, facility_group: facility_group_2) }
  let!(:owner) { create(:admin, :power_user, organization: ihmi) }

  login_page = AdminPage::Sessions::New.new
  dashboard = OrganizationsPage::Index.new
  dashboard_navigation = Navigations::DashboardPageNavigation.new
  org_page = AdminPage::Organizations::Index.new

  it "Verify organization is displayed in dashboard" do
    visit reports_regions_path
    login_page.do_login(owner.email, owner.password)

    #
    # two organizations
    expect(dashboard.all_elements(css: ".card").size).to eq(2)
    expect(page).to have_content("IHMI")
  end

  it "Verify organisation name/count get updated in dashboard when new org is added via manage section" do
    visit root_path
    login_page.do_login(owner.email, owner.password)

    # total number of organization present in dashboard
    visit reports_regions_path
    original_org_count = dashboard.all_elements(css: ".card.organization").count

    dashboard_navigation.click_manage_option("#nav-organizations-link")

    org_page.click_on_add_organization_button
    AdminPage::Organizations::New.new.create_new_organization("test", "testDescription")

    # assertion at organization screen
    expect(page).to have_content("Organization was successfully created.")
    org_page.is_organization_name_present("Test")

    # Dashboard doesn't show Organizations without any facilities
    fg = create(:facility_group, organization: Organization.find_by!(name: "Test"))
    create(:facility, facility_group: fg)

    dashboard_navigation.click_main_menu_tab("Reports")

    # assertion at dashboard screen
    expect(page).to have_content("Test")

    expect(dashboard.get_organization_count).to eq(original_org_count + 1)
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
