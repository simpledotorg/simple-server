# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminAccessPresenter, type: :model do
  let(:current_admin) { create(:admin, :manager) }
  let(:presenter) { described_class.new(current_admin) }

  context "#display_access_level" do
    it "pulls out the access level information for the current user" do
      access_level = presenter.display_access_level

      expect(access_level.name).to eq("Manager")
      expect(access_level.description).to eq("Can manage regions, facilities, admins, users, and view everything")
      expect(access_level.grant_access).to match_array([:call_center, :viewer_reports_only, :viewer_all, :manager])
    end
  end

  context "#permitted_access_levels" do
    it "pulls out the permitted access levels that you can grant to another user" do
      expected = [
        {
          id: :manager,
          name: "Manager",
          grant_access: [:call_center, :viewer_reports_only, :viewer_all, :manager],
          description: "Can manage regions, facilities, admins, users, and view everything"
        },

        {
          id: :viewer_reports_only,
          name: "View: Reports only",
          grant_access: [],
          description: "Can only view reports"
        },

        {
          id: :viewer_all,
          name: "View: Everything",
          grant_access: [],
          description: "Can view patient data and all facility data"
        },

        {
          id: :call_center,
          name: "Call center staff",
          grant_access: [],
          description: "Can only manage overdue patients list"
        }
      ]

      expect(presenter.permitted_access_levels).to match_array(expected)
    end
  end

  context "#visible_access_tree" do
    let!(:organization_1) { create(:organization) }
    let!(:organization_2) { create(:organization) }
    let!(:facility_group_1_in_org_1) { create(:facility_group, organization: organization_1) }
    let!(:facility_group_2_in_org_1) { create(:facility_group, organization: organization_1) }
    let!(:facility_group_1_in_org_2) { create(:facility_group, organization: organization_2) }
    let!(:facility_group_2_in_org_2) { create(:facility_group, organization: organization_2) }
    let!(:facilities_in_fg_1_org_1) { create_list(:facility, 2, facility_group: facility_group_1_in_org_1) }
    let!(:facilities_in_fg_2_org_1) { create_list(:facility, 2, facility_group: facility_group_2_in_org_1) }
    let!(:facilities_in_fg_1_org_2) { create_list(:facility, 2, facility_group: facility_group_1_in_org_2) }
    let!(:facilities_in_fg_2_org_2) { create_list(:facility, 2, facility_group: facility_group_2_in_org_2) }

    context "show the depth of the tree based on the scope of your access" do
      it "returns the org-level tree if the access is across orgs" do
        current_admin.accesses.create!(resource: organization_1)
        current_admin.accesses.create!(resource: organization_2)
        current_admin.reload

        expected = {
          render_partial: "email_authentications/invitations/organization_access_tree",
          root: :organization
        }

        expect(presenter.visible_access_tree.slice(:root, :render_partial)).to eq(expected)
      end

      it "returns the fg-level tree if the access is across facility groups within an org" do
        current_admin.accesses.create!(resource: facility_group_1_in_org_1)
        current_admin.accesses.create!(resource: facility_group_2_in_org_1)
        current_admin.reload

        expected = {
          render_partial: "email_authentications/invitations/facility_group_access_tree",
          root: :facility_group
        }

        expect(presenter.visible_access_tree.slice(:root, :render_partial)).to eq(expected)
      end

      it "returns the facility-level tree if the access is within a facility group" do
        current_admin.accesses.create!(resource: facilities_in_fg_1_org_1.first)
        current_admin.reload

        expected = {
          render_partial: "email_authentications/invitations/facility_access_tree",
          root: :facility
        }

        expect(presenter.visible_access_tree.slice(:root, :render_partial)).to eq(expected)
      end

      it "returns the fg-level tree if access to facilities is across facility groups" do
        current_admin.accesses.create!(resource: facilities_in_fg_1_org_1.first)
        current_admin.accesses.create!(resource: facilities_in_fg_2_org_1.first)
        current_admin.reload

        expected = {
          render_partial: "email_authentications/invitations/facility_group_access_tree",
          root: :facility_group
        }

        expect(presenter.visible_access_tree.slice(:root, :render_partial)).to eq(expected)
      end

      it "returns the org-level tree if access to facilities is across orgs" do
        current_admin.accesses.create!(resource: facilities_in_fg_1_org_1.first)
        current_admin.accesses.create!(resource: facilities_in_fg_1_org_2.first)
        current_admin.reload

        expected = {
          render_partial: "email_authentications/invitations/organization_access_tree",
          root: :organization
        }

        expect(presenter.visible_access_tree.slice(:root, :render_partial)).to eq(expected)
      end
    end
  end

  context "#organization_tree" do
    let!(:organization) { create(:organization) }
    let!(:facility_group) { create(:facility_group, organization: organization) }
    let!(:facility) { create(:facility, facility_group: facility_group) }

    it "returns a data-structure to render a full access tree" do
      current_admin.accesses.create!(resource: organization)
      current_admin.reload

      expected = {
        organization => {
          facility_group => [facility]
        }
      }

      expect(presenter.organization_tree).to eq(expected)
    end
  end

  context "#facility_group_tree" do
    let!(:organization) { create(:organization) }
    let!(:facility_group) { create(:facility_group, organization: organization) }
    let!(:facility) { create(:facility, facility_group: facility_group) }

    it "returns a data-structure to render a full access tree" do
      current_admin.accesses.create!(resource: facility_group)
      current_admin.reload

      expected = {
        facility_group => [facility]
      }

      expect(presenter.facility_group_tree).to eq(expected)
    end

    it "does not return facility groups without facilities" do
      fg_without_facilities = create(:facility_group, organization: organization)

      current_admin.accesses.create!(resource: facility_group)
      current_admin.accesses.create!(resource: fg_without_facilities)
      current_admin.reload

      expected = {
        facility_group => [facility]
      }

      expect(presenter.facility_group_tree).to eq(expected)
    end
  end
end
