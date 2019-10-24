require 'rails_helper'

RSpec.feature "Home page", type: :feature do
  let!(:ihmi) { create(:organization, name: "IHMI") }
  let!(:path) { create(:organization, name: "PATH") }

  let!(:ihmi_group_bathinda) { create(:facility_group, organization: ihmi, name: "Bathinda") }
  let!(:ihmi_group_mansa) { create(:facility_group, organization: ihmi, name: "Mansa") }
  let!(:path_group) { create(:facility_group, organization: path, name: "Amir Singh Facility Group") }

  let!(:bathinda_chc) { create(:facility, facility_group: ihmi_group_bathinda, name: "CHC Buccho") }
  let!(:bathinda_phc) { create(:facility, facility_group: ihmi_group_bathinda, name: "PHC Batala") }
  let!(:mansa_phc) { create(:facility, facility_group: ihmi_group_mansa, name: "PHC Joga") }
  let!(:path_clinic) { create(:facility, facility_group: path_group, name: "Dr. Amir Singh") }

  context "owner" do
    let!(:owner) { create(:admin, :owner, email: "owner@example.com") }

    before do
      sign_in(owner)
      visit root_path
    end

    it "shows all organizations" do
      expect(page).to have_content("IHMI")
      expect(page).to have_content("PATH")
    end
  end

  context "supervisor in bathinda" do
    let!(:supervisor) { create(:admin, :supervisor, email: "supervisor@example.com") }
    let!(:access_controls) { create(:admin_access_control, admin: supervisor, access_controllable: bathinda_chc.facility_group) }
    let!(:new_user) { create(:user, :sync_requested, facility: bathinda_chc) }

    before do
      sign_in(supervisor)
      visit root_path
    end

    it "shows supervisor's organization" do
      expect(page).to have_content("IHMI")
    end

    it "doesn't show other organizations" do
      expect(page).not_to have_content("PATH")
    end
  end
end
