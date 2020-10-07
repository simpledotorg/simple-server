require "rails_helper"

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

  before do
    enable_flag(:new_permissions_system_aug_2020, admin)
    sign_in(admin.email_authentication)
    # Root path has moved to MyFacilities#Overview
    # visit root_path
    visit reports_regions_path
  end

  after do
    disable_flag(:new_permissions_system_aug_2020, admin)
  end

  context "owner has permission to view cohort reports" do
    context "for all organizations" do
      let(:admin) do
        create(:admin, :power_user)
      end

      it "shows all organizations" do
        expect(page).to have_content("IHMI")
        expect(page).to have_content("PATH")
      end

      it "shows all the districts" do
        districts = Facility.all.pluck(:district).uniq

        districts.each do |district|
          expect(page).to have_content(district)
        end
      end
    end

    context "for a specific organization" do
      let(:admin) do
        create(:admin, :manager, accesses: [build(:access, resource: ihmi)])
      end

      it "shows the authorized organization" do
        expect(page).to have_content("IHMI")
      end

      it "doesn't show other organizations" do
        expect(page).not_to have_content("PATH")
      end

      it "shows districts for facilities in the organization" do
        districts = ihmi.facilities.pluck(:district).uniq

        districts.each do |district|
          expect(page).to have_content(district)
        end
      end
    end

    context "for a specific facility group" do
      let(:admin) do
        create(:admin, :manager, accesses: [build(:access, resource: ihmi_group_bathinda)])
      end

      it "shows the organization of the facility group" do
        expect(page).to have_content("IHMI")
      end

      it "doesn't show other organizations" do
        expect(page).not_to have_content("PATH")
      end

      it "shows districts for facilities in the organization" do
        districts = ihmi_group_bathinda.facilities.pluck(:district).uniq

        districts.each do |district|
          expect(page).to have_content(district)
        end
      end
    end
  end
end
