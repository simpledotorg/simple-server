require 'rails_helper'

RSpec.feature "Dashboards", type: :feature do
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

    it "shows all facility groups" do
      expect(page).to have_link("Bathinda")
      expect(page).to have_link("Mansa")
      expect(page).to have_link("Amir Singh Facility Group")
    end

    it "links to the facility group" do
      click_link "Bathinda"
      expect(current_path).to eq facility_group_path(ihmi_group_bathinda)
    end
  end

  context "organization owner" do
  end

  context "supervisor in bathinda" do
    let!(:supervisor) { create(:admin, :supervisor, email: "supervisor@example.com") }
    let!(:access_controls) { create(:admin_access_control, admin: supervisor, access_controllable: bathinda.facility_group) }
    let!(:new_user) { create(:user, :sync_requested, facility: bathinda) }

    skip "shows all facilities" do
      expect(page).to have_content("CHC Buccho")
      expect(page).to have_content("PHC Batala")
      expect(page).to have_content("PHC Joga")
      expect(page).to have_content("Dr. Amir Singh")
    end
  end

  context "analyst" do
  end

end
