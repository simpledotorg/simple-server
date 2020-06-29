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
    sign_in(admin.email_authentication)
    visit root_path
  end

  context "owner has permission to view cohort reports" do
    context "for all organizations" do
      let(:admin) do
        create(:admin, user_permissions: [
          build(:user_permission, permission_slug: :view_cohort_reports, resource: nil)
        ])
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
        create(:admin, user_permissions: [
          build(:user_permission, permission_slug: :view_cohort_reports, resource: ihmi)
        ])
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
        create(:admin, user_permissions: [
          build(:user_permission, permission_slug: :view_cohort_reports, resource: ihmi_group_bathinda)
        ])
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

  context "user has permission to approve health care workers" do
    let!(:user1) { create(:user, :with_phone_number_authentication, sync_approval_status: :requested) }
    let!(:user2) { create(:user, :with_phone_number_authentication, sync_approval_status: :requested) }

    before do
      user1.sync_approval_status = :requested
      user1.save

      user2.sync_approval_status = :requested
      user2.save
    end

    context "for all organizations" do
      let(:admin) do
        create(:admin, user_permissions: [
          build(:user_permission, permission_slug: :approve_health_workers, resource: nil)
        ])
      end

      it "lists all users requesting approval" do
        visit root_path
        expect(page).to have_content(user1.full_name)
        expect(page).to have_content(user2.full_name)
      end
    end

    context "for a specific facility group" do
      let(:admin) do
        create(:admin, user_permissions: [
          build(:user_permission, permission_slug: :approve_health_workers, resource: user1.registration_facility.facility_group)
        ])
      end

      it "lists all users requesting approval in authorized facility group" do
        expect(page).to have_content(user1.full_name)
      end

      it "does not list other users" do
        expect(page).not_to have_content(user2.full_name)
      end
    end

    context "for a specific organization" do
      let(:admin) do
        create(:admin, user_permissions: [
          build(:user_permission, permission_slug: :approve_health_workers, resource: user1.organization)
        ])
      end

      it "lists all users requesting approval in authorized organization" do
        expect(page).to have_content(user1.full_name)
      end

      it "does not list other users" do
        expect(page).not_to have_content(user2.full_name)
      end
    end
  end
end
