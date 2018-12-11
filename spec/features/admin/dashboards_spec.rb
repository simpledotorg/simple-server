require 'rails_helper'

RSpec.feature "Dashboards", type: :feature do
  let!(:supervisor) { create(:admin, :supervisor, email: "supervisor@example.com") }
  let!(:bathinda) { create(:facility, name: "Bathinda") }
  let!(:new_user) { create(:user, :sync_requested, facility: bathinda) }

  before do
    sign_in(supervisor)
    visit admin_dashboard_path
  end

  it "shows a basic dashboard" do
    expect(page).to have_content("Daily unique patients")
    expect(page).to have_content("New patients registered")
    expect(page).to have_content("Monthly unique patients")
  end

  context "outstanding approval requests" do
    it "shows a task list for approvals" do
      expect(page).to have_content("1 user waiting for access")

      within find(".card", text: new_user.full_name) do
        expect(page).to have_content(new_user.phone_number)
        expect(page).to have_content("Bathinda")
        expect(page).to have_link("Allow access")
        expect(page).to have_link("Deny access")
      end
    end

    it "lets admins allow access" do
      within find(".card", text: new_user.full_name) do
        click_link "Allow access"
      end

      expect(page).not_to have_content(new_user.full_name)

      new_user.reload
      expect(new_user.sync_approval_status).to eq("allowed")
    end

    it "lets admins deny access" do
      within find(".card", text: new_user.full_name) do
        click_link "Deny access"
        fill_in "reason_for_denial", with: 'reason for denial'
        find('input[name="commit"]').click
      end

      expect(page).not_to have_content(new_user.full_name)

      new_user.reload
      expect(new_user.sync_approval_status).to eq("denied")
    end
  end
end
