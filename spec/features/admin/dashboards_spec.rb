require 'rails_helper'

RSpec.feature "Dashboards", type: :feature do
  let!(:supervisor) { create(:admin, :supervisor, email: "supervisor@example.com") }

  let!(:bathinda) { create(:facility, name: "Bathinda") }
  let!(:mansa) { create(:facility, name: "Mansa") }

  let!(:new_user) { create(:user, :sync_requested, facilities: [bathinda, mansa]) }

  before do
    sign_in(supervisor)
    visit admin_dashboard_path
  end

  it "shows a basic dashboard" do
    expect(page).to have_content("Patients Registered")
  end

  context "outstanding approval requests" do
    it "shows a task list for approvals" do
      expect(page).to have_content("Users waiting for approval")

      within find("tr", text: new_user.full_name) do
        expect(page).to have_content(new_user.phone_number)
        expect(page).to have_content("Bathinda, Mansa")
        expect(page).to have_link("Approve Sync Access")
      end
    end
  end
end
