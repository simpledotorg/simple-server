# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserAccess, type: :model do
  let(:viewer_all) { UserAccess.new(create(:admin, :viewer_all)) }
  let(:manager) { UserAccess.new(create(:admin, :manager)) }
  let(:power_user) { UserAccess.new(create(:admin, :power_user)) }

  describe "can_access?" do
    let(:admin) { build(:user, access_level: :viewer_all) }

    it "raises error for invalid resource" do
      [Region, ProtocolDrug, User, Protocol].each do |klass|
        resource = klass.new
        expect {
          admin.can_access?(resource, :manage)
        }.to raise_error(UserAccess::UnsupportedAccessRequest, "can only be called with a Facility, FacilityGroup, or Organization")
      end
    end

    it "raises for invalid action" do
      expect {
        admin.can_access?(Facility.new, :foo)
      }.to raise_error(ArgumentError, /unknown action foo/)
      expect {
        admin.can_access?(Facility.new, nil)
      }.to raise_error(ArgumentError, /unknown action /)
    end

    it "returns for a valid resource" do
      [Facility, FacilityGroup, Organization].each do |klass|
        resource = klass.new
        expect(admin.can_access?(resource, :manage)).to be false
      end
    end
  end

  describe "accessible_*" do
    let(:organization_1) { create(:organization, name: "org_1") }
    let(:organization_2) { create(:organization, name: "org_2") }
    let(:organization_3) { create(:organization, name: "org_3") }

    let(:facility_group_1) { create(:facility_group, organization: organization_1, name: "facility_group_1") }
    let(:facility_group_2) { create(:facility_group, organization: organization_2, name: "facility_group_2") }
    let(:facility_group_3_1) { create(:facility_group, organization: organization_3, name: "facility_group_3_1") }
    let(:facility_group_3_2) { create(:facility_group, organization: organization_3, name: "facility_group_3_2") }

    let(:facility_1) { create(:facility, facility_group: facility_group_1) }
    let(:facility_2) { create(:facility, facility_group: facility_group_2) }
    let(:facility_3) { create(:facility, facility_group: facility_group_3_1) }
    let(:facility_4) { create(:facility, facility_group: facility_group_3_2) }
    let(:facility_5) { create(:facility) }
    let(:facility_6) { create(:facility) }
    let(:other_facility) { create(:facility, name: "other facility") }

    let(:user_1) { create(:user, :with_phone_number_authentication, registration_facility: facility_1) }
    let(:user_2) { create(:user, :with_phone_number_authentication, registration_facility: facility_2) }
    let(:user_3) { create(:user, :with_phone_number_authentication, registration_facility: facility_3) }
    let(:user_4) { create(:user, :with_phone_number_authentication, registration_facility: facility_4) }
    let(:user_5) { create(:user, :with_phone_number_authentication, registration_facility: facility_5) }

    let(:admin_1) { create(:admin, :call_center, :with_access, full_name: "admin_1", resource: organization_1) }
    let(:admin_2) { create(:admin, :call_center, :with_access, full_name: "admin_2", resource: organization_1) }
    let(:admin_3) { create(:admin, :call_center, :with_access, full_name: "admin_3", resource: organization_3) }
    let(:admin_4) { create(:admin, :call_center, :with_access, full_name: "admin_4", resource: organization_3) }
    let(:admin_5) { create(:admin, :call_center, full_name: "admin_5") }

    let(:manager) { create(:admin, :manager, full_name: "manager") }
    let(:viewer_all) { create(:admin, :viewer_all, full_name: "viewer_all") }
    let(:viewer_reports_only) { create(:admin, :viewer_reports_only, full_name: "viewer_reports_only") }
    let(:call_center) { create(:admin, :call_center, full_name: "call_center") }

    let(:protocol_1) { create(:protocol) }
    let(:protocol_drug_1) { create(:protocol_drug) }

    context "non power users" do
      context "#accessible_organizations" do
        let!(:permission_matrix) {
          [
            [manager, :manage, organization_3, [organization_3]],
            [manager, :view_pii, organization_3, [organization_3]],
            [manager, :view_reports, organization_3, [organization_3]],
            [manager, :manage_overdue_list, organization_3, [organization_3]],

            [viewer_all, :manage, organization_3, []],
            [viewer_all, :view_pii, organization_3, [organization_3]],
            [viewer_all, :view_reports, organization_3, [organization_3]],
            [viewer_all, :manage_overdue_list, organization_3, [organization_3]],

            [viewer_reports_only, :manage, organization_3, []],
            [viewer_reports_only, :view_pii, organization_3, []],
            [viewer_reports_only, :view_reports, organization_3, [organization_3]],
            [viewer_reports_only, :manage_overdue_list, organization_3, []],

            [call_center, :manage, organization_3, []],
            [call_center, :view_pii, organization_3, []],
            [call_center, :view_reports, organization_3, []],
            [call_center, :manage_overdue_list, organization_3, [organization_3]]
          ]
        }

        it "returns the organizations an admin can perform actions on" do
          permission_matrix.each do |admin, action, current_resource, expected_resources|
            admin.accesses.create!(resource: current_resource)

            expect(admin.accessible_organizations(action)).to match_array(expected_resources),
              error_message(admin,
                action,
                expected_resources,
                admin.accessible_organizations(action))
            expected_resources.each { |resource| expect(admin.can_access?(current_resource, action)).to be_truthy }
            expect(admin.can_access?(organization_1, action)).to be_falsey
            admin.accesses.delete_all
          end
        end
      end

      context "#accessible_facility_groups" do
        context "Organization access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, organization_3, [facility_group_3_1, facility_group_3_2]],
              [manager, :view_pii, organization_3, [facility_group_3_1, facility_group_3_2]],
              [manager, :view_reports, organization_3, [facility_group_3_1, facility_group_3_2]],
              [manager, :manage_overdue_list, organization_3, [facility_group_3_1, facility_group_3_2]],

              [viewer_all, :manage, organization_3, []],
              [viewer_all, :view_pii, organization_3, [facility_group_3_1, facility_group_3_2]],
              [viewer_all, :view_reports, organization_3, [facility_group_3_1, facility_group_3_2]],
              [viewer_all, :manage_overdue_list, organization_3, [facility_group_3_1, facility_group_3_2]],

              [viewer_reports_only, :manage, organization_3, []],
              [viewer_reports_only, :view_pii, organization_3, []],
              [viewer_reports_only, :view_reports, organization_3, [facility_group_3_1, facility_group_3_2]],
              [viewer_reports_only, :manage_overdue_list, organization_3, []],

              [call_center, :manage, organization_3, []],
              [call_center, :view_pii, organization_3, []],
              [call_center, :view_reports, organization_3, []],
              [call_center, :manage_overdue_list, organization_3, [facility_group_3_1, facility_group_3_2]]
            ]
          }

          it "returns the facility groups an admin can perform actions on with organization access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create!(resource: current_resource)

              expect(admin.accessible_facility_groups(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_facility_groups(action))
              expected_resources.each { |resource| expect(admin.can_access?(current_resource, action)).to be_truthy }
              admin.accesses.delete_all
            end
          end
        end

        context "Facility Group access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, facility_group_1, [facility_group_1]],
              [manager, :view_pii, facility_group_1, [facility_group_1]],
              [manager, :view_reports, facility_group_1, [facility_group_1]],
              [manager, :manage_overdue_list, facility_group_1, [facility_group_1]],

              [viewer_all, :manage, facility_group_1, []],
              [viewer_all, :view_pii, facility_group_1, [facility_group_1]],
              [viewer_all, :view_reports, facility_group_1, [facility_group_1]],
              [viewer_all, :manage_overdue_list, facility_group_1, [facility_group_1]],

              [viewer_reports_only, :manage, facility_group_1, []],
              [viewer_reports_only, :view_pii, facility_group_1, []],
              [viewer_reports_only, :view_reports, facility_group_1, [facility_group_1]],
              [viewer_reports_only, :manage_overdue_list, facility_group_1, []],

              [call_center, :manage, facility_group_1, []],
              [call_center, :view_pii, facility_group_1, []],
              [call_center, :view_reports, facility_group_1, []],
              [call_center, :manage_overdue_list, facility_group_1, [facility_group_1]]
            ]
          }

          it "returns the facility groups an admin can perform actions on with facility group access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create!(resource: current_resource)
              expect(admin.accessible_facility_groups(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_facility_groups(action))
              expected_resources.each { |resource| expect(admin.can_access?(current_resource, action)).to be_truthy }
              admin.accesses.delete_all
            end
          end
        end
      end

      context "#accessible_state_regions" do
        it "managers of a district have view_reports access to the districts' states" do
          state_1 = Region.create!(name: "state 1", region_type: "state", reparent_to: Region.root)
          state_2 = Region.create!(name: "state 2", region_type: "state", reparent_to: Region.root)
          facility_group_1 = create(:facility_group, name: "district 1", state: state_1.name)
          facility_group_2 = create(:facility_group, name: "district 2", state: state_2.name)
          district_1 = facility_group_1.region
          district_2 = facility_group_2.region
          viewer_reports_only.accesses.create!(resource: district_1.source)
          expect(viewer_reports_only.user_access.accessible_state_regions(:view_reports)).to be_empty
          manager.accesses.create!(resource: district_1.source)
          expect(manager.user_access.accessible_state_regions(:view_reports)).to match_array([district_1.state_region])
          expect(manager.user_access.accessible_state_regions(:view_reports)).to_not match_array([district_2.state_region])
        end

        it "power users have view_reports access to all states" do
          power_user = create(:admin, :power_user)
          _facility_group_1 = create(:facility_group, name: "district 1")
          _facility_group_2 = create(:facility_group, name: "district 2")
          state_regions = Region.state_regions
          expect(power_user.user_access.accessible_state_regions(:view_reports).count).to eq(state_regions.count)
          expect(power_user.user_access.accessible_state_regions(:view_reports)).to match_array(state_regions)
        end

        it "for other actions: returns UnsupportedOperation" do
          expect {
            manager.user_access.accessible_state_regions(:manage)
          }.to raise_error(UserAccess::UnsupportedAccessRequest)
        end
      end

      context "#accessible_blocks" do
        it "returns any blocks in the org an admin manages" do
          block_1 = create(:region, :block, reparent_to: facility_group_3_1.region)
          block_2 = create(:region, :block, reparent_to: facility_group_3_2.region)
          _block_3 = create(:region, :block, name: "block_1", reparent_to: facility_group_1.region)
          manager.accesses.create!(resource: organization_3)
          expect(manager.accessible_block_regions(:manage)).to match_array([block_1, block_2])
          viewer_all.accesses.create!(resource: organization_3)
          expect(viewer_all.accessible_block_regions(:manage)).to match_array([])
          expect(viewer_all.accessible_block_regions(:view_reports)).to match_array([block_1, block_2])
        end

        it "returns any blocks underneath any accessible_facility groups" do
          block_1 = create(:region, :block, name: "block_1", reparent_to: facility_group_1.region)
          block_2 = create(:region, :block, reparent_to: facility_group_2.region)
          _block_3 = create(:region, :block, reparent_to: facility_group_3_1.region)
          manager.accesses.create!(resource: facility_group_1)
          expect(manager.accessible_block_regions(:manage)).to match_array([block_1])
          manager.accesses.create!(resource: facility_group_2)
          expect(manager.accessible_block_regions(:manage)).to match_array([block_1, block_2])
        end
      end

      context "#accessible_facilities" do
        context "Organization access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, organization_3, [facility_3, facility_4]],
              [manager, :view_pii, organization_3, [facility_3, facility_4]],
              [manager, :view_reports, organization_3, [facility_3, facility_4]],
              [manager, :manage_overdue_list, organization_3, [facility_3, facility_4]],

              [viewer_all, :manage, organization_3, []],
              [viewer_all, :view_pii, organization_3, [facility_3, facility_4]],
              [viewer_all, :view_reports, organization_3, [facility_3, facility_4]],
              [viewer_all, :manage_overdue_list, organization_3, [facility_3, facility_4]],

              [viewer_reports_only, :manage, organization_3, []],
              [viewer_reports_only, :view_pii, organization_3, []],
              [viewer_reports_only, :view_reports, organization_3, [facility_3, facility_4]],
              [viewer_reports_only, :manage_overdue_list, organization_3, []],

              [call_center, :manage, organization_3, []],
              [call_center, :view_pii, organization_3, []],
              [call_center, :view_reports, organization_3, []],
              [call_center, :manage_overdue_list, organization_3, [facility_3, facility_4]]
            ]
          }

          it "returns the facilities an admin can perform actions on with organization access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create!(resource: current_resource)

              expect(admin.accessible_facilities(action)).to match_array(expected_resources)
              expected_resources.each { |resource| expect(admin.can_access?(resource, action)).to be_truthy }
              admin.accesses.delete_all
            end
          end
        end

        context "Facility Group access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, facility_group_1, [facility_1]],
              [manager, :view_pii, facility_group_1, [facility_1]],
              [manager, :view_reports, facility_group_1, [facility_1]],
              [manager, :manage_overdue_list, facility_group_1, [facility_1]],

              [viewer_all, :manage, facility_group_1, []],
              [viewer_all, :view_pii, facility_group_1, [facility_1]],
              [viewer_all, :view_reports, facility_group_1, [facility_1]],
              [viewer_all, :manage_overdue_list, facility_group_1, [facility_1]],

              [viewer_reports_only, :manage, facility_group_1, []],
              [viewer_reports_only, :view_pii, facility_group_1, []],
              [viewer_reports_only, :view_reports, facility_group_1, [facility_1]],
              [viewer_reports_only, :manage_overdue_list, facility_group_1, []],

              [call_center, :manage, facility_group_1, []],
              [call_center, :view_pii, facility_group_1, []],
              [call_center, :view_reports, facility_group_1, []],
              [call_center, :manage_overdue_list, facility_group_1, [facility_1]]
            ]
          }

          it "returns the facilities an admin can perform actions on with facility group access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create!(resource: current_resource)

              expect(admin.accessible_facilities(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_facilities(action))
              expected_resources.each { |resource| expect(admin.can_access?(resource, action)).to be_truthy }
              expect(admin.can_access?(other_facility, action)).to be_falsey

              admin.accesses.delete_all
            end
          end
        end

        context "Facility access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, facility_5, [facility_5]],
              [manager, :view_pii, facility_5, [facility_5]],
              [manager, :view_reports, facility_5, [facility_5]],
              [manager, :manage_overdue_list, facility_5, [facility_5]],

              [viewer_all, :manage, facility_5, []],
              [viewer_all, :view_pii, facility_5, [facility_5]],
              [viewer_all, :view_reports, facility_5, [facility_5]],
              [viewer_all, :manage_overdue_list, facility_5, [facility_5]],

              [viewer_reports_only, :manage, facility_5, []],
              [viewer_reports_only, :view_pii, facility_5, []],
              [viewer_reports_only, :view_reports, facility_5, [facility_5]],
              [viewer_reports_only, :manage_overdue_list, facility_5, []],

              [call_center, :manage, facility_5, []],
              [call_center, :view_pii, facility_5, []],
              [call_center, :view_reports, facility_5, []],
              [call_center, :manage_overdue_list, facility_5, [facility_5]]
            ]
          }

          it "returns false for can_access for facilities without access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              result = admin.can_access?(other_facility, action)
              expect(result).to be_falsey, "admin #{admin.full_name} should not have access to #{other_facility.name} with #{action}, but got #{result}"
            end
          end

          it "returns the facilities an admin can perform actions on with facility access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create!(resource: current_resource)

              expect(admin.accessible_facilities(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_facilities(action))
              expected_resources.each { |resource| expect(admin.can_access?(resource, action)).to be_truthy }
              admin.accesses.delete_all
            end
          end
        end
      end

      context "#accessible_users" do
        context "Organization access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, organization_3, [user_3, user_4]],
              [manager, :view_pii, organization_3, [user_3, user_4]],
              [manager, :view_reports, organization_3, [user_3, user_4]],
              [manager, :manage_overdue_list, organization_3, []],

              [viewer_all, :manage, organization_3, []],
              [viewer_all, :view_pii, organization_3, [user_3, user_4]],
              [viewer_all, :view_reports, organization_3, [user_3, user_4]],
              [viewer_all, :manage_overdue_list, organization_3, []],

              [viewer_reports_only, :manage, organization_3, []],
              [viewer_reports_only, :view_pii, organization_3, []],
              [viewer_reports_only, :view_reports, organization_3, [user_3, user_4]],
              [viewer_reports_only, :manage_overdue_list, organization_3, []],

              [call_center, :manage, organization_3, []],
              [call_center, :view_pii, organization_3, []],
              [call_center, :view_reports, organization_3, []],
              [call_center, :manage_overdue_list, organization_3, []]
            ]
          }

          it "returns the users an admin can perform actions on with organization access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create!(resource: current_resource)
              expect(admin.accessible_users(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_users(action))
              admin.accesses.delete_all
            end
          end
        end

        context "Facility Group access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, facility_group_1, [user_1]],
              [manager, :view_pii, facility_group_1, [user_1]],
              [manager, :view_reports, facility_group_1, [user_1]],
              [manager, :manage_overdue_list, facility_group_1, []],

              [viewer_all, :manage, facility_group_1, []],
              [viewer_all, :view_pii, facility_group_1, [user_1]],
              [viewer_all, :view_reports, facility_group_1, [user_1]],
              [viewer_all, :manage_overdue_list, facility_group_1, []],

              [viewer_reports_only, :manage, facility_group_1, []],
              [viewer_reports_only, :view_pii, facility_group_1, []],
              [viewer_reports_only, :view_reports, facility_group_1, [user_1]],
              [viewer_reports_only, :manage_overdue_list, facility_group_1, []],

              [call_center, :manage, facility_group_1, []],
              [call_center, :view_pii, facility_group_1, []],
              [call_center, :view_reports, facility_group_1, []],
              [call_center, :manage_overdue_list, facility_group_1, []]
            ]
          }

          it "returns the users an admin can perform actions on with facility group access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create!(resource: current_resource)
              expect(admin.accessible_users(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_users(action))
              admin.accesses.delete_all
            end
          end
        end

        context "Facility access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, facility_5, [user_5]],
              [manager, :view_pii, facility_5, [user_5]],
              [manager, :view_reports, facility_5, [user_5]],
              [manager, :manage_overdue_list, facility_5, []],

              [viewer_all, :manage, facility_5, []],
              [viewer_all, :view_pii, facility_5, [user_5]],
              [viewer_all, :view_reports, facility_5, [user_5]],
              [viewer_all, :manage_overdue_list, facility_5, []],

              [viewer_reports_only, :manage, facility_5, []],
              [viewer_reports_only, :view_pii, facility_5, []],
              [viewer_reports_only, :view_reports, facility_5, [user_5]],
              [viewer_reports_only, :manage_overdue_list, facility_5, []],

              [call_center, :manage, facility_5, []],
              [call_center, :view_pii, facility_5, []],
              [call_center, :view_reports, facility_5, []],
              [call_center, :manage_overdue_list, facility_5, []]
            ]
          }

          it "returns the users an admin can perform actions on with facility access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create!(resource: current_resource)
              expect(admin.accessible_users(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_users(action))
              admin.accesses.delete_all
            end
          end
        end
      end

      context "#accessible_protocols" do
        context "Organization access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, organization_3, Protocol.all],
              [manager, :view_pii, organization_3, []],
              [manager, :view_reports, organization_3, []],
              [manager, :manage_overdue_list, organization_3, []],

              [viewer_all, :manage, organization_3, []],
              [viewer_all, :view_pii, organization_3, []],
              [viewer_all, :view_reports, organization_3, []],
              [viewer_all, :manage_overdue_list, organization_3, []],

              [viewer_reports_only, :manage, organization_3, []],
              [viewer_reports_only, :view_pii, organization_3, []],
              [viewer_reports_only, :view_reports, organization_3, []],
              [viewer_reports_only, :manage_overdue_list, organization_3, []],

              [call_center, :manage, organization_3, []],
              [call_center, :view_pii, organization_3, []],
              [call_center, :view_reports, organization_3, []],
              [call_center, :manage_overdue_list, organization_3, []]
            ]
          }

          it "returns the protocols an admin can perform actions on with organization access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create!(resource: current_resource)
              expect(admin.accessible_protocols(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_protocols(action))
              admin.accesses.delete_all
            end
          end
        end

        context "Facility Group access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, facility_group_1, []],
              [manager, :view_pii, facility_group_1, []],
              [manager, :view_reports, facility_group_1, []],
              [manager, :manage_overdue_list, facility_group_1, []],

              [viewer_all, :manage, facility_group_1, []],
              [viewer_all, :view_pii, facility_group_1, []],
              [viewer_all, :view_reports, facility_group_1, []],
              [viewer_all, :manage_overdue_list, facility_group_1, []],

              [viewer_reports_only, :manage, facility_group_1, []],
              [viewer_reports_only, :view_pii, facility_group_1, []],
              [viewer_reports_only, :view_reports, facility_group_1, []],
              [viewer_reports_only, :manage_overdue_list, facility_group_1, []],

              [call_center, :manage, facility_group_1, []],
              [call_center, :view_pii, facility_group_1, []],
              [call_center, :view_reports, facility_group_1, []],
              [call_center, :manage_overdue_list, facility_group_1, []]
            ]
          }

          it "returns the protocols an admin can perform actions on with facility group access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create!(resource: current_resource)
              expect(admin.accessible_protocols(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_protocols(action))
              admin.accesses.delete_all
            end
          end
        end

        context "Facility access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, facility_5, []],
              [manager, :view_pii, facility_5, []],
              [manager, :view_reports, facility_5, []],
              [manager, :manage_overdue_list, facility_5, []],

              [viewer_all, :manage, facility_5, []],
              [viewer_all, :view_pii, facility_5, []],
              [viewer_all, :view_reports, facility_5, []],
              [viewer_all, :manage_overdue_list, facility_5, []],

              [viewer_reports_only, :manage, facility_5, []],
              [viewer_reports_only, :view_pii, facility_5, []],
              [viewer_reports_only, :view_reports, facility_5, []],
              [viewer_reports_only, :manage_overdue_list, facility_5, []],

              [call_center, :manage, facility_5, []],
              [call_center, :view_pii, facility_5, []],
              [call_center, :view_reports, facility_5, []],
              [call_center, :manage_overdue_list, facility_5, []]
            ]
          }

          it "returns the protocols an admin can perform actions on with facility access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create!(resource: current_resource)
              expect(admin.accessible_protocols(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_protocols(action))
              admin.accesses.delete_all
            end
          end
        end
      end

      context "#accessible_protocol_drugs" do
        context "Organization access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, organization_3, ProtocolDrug.all],
              [manager, :view_pii, organization_3, []],
              [manager, :view_reports, organization_3, []],
              [manager, :manage_overdue_list, organization_3, []],

              [viewer_all, :manage, organization_3, []],
              [viewer_all, :view_pii, organization_3, []],
              [viewer_all, :view_reports, organization_3, []],
              [viewer_all, :manage_overdue_list, organization_3, []],

              [viewer_reports_only, :manage, organization_3, []],
              [viewer_reports_only, :view_pii, organization_3, []],
              [viewer_reports_only, :view_reports, organization_3, []],
              [viewer_reports_only, :manage_overdue_list, organization_3, []],

              [call_center, :manage, organization_3, []],
              [call_center, :view_pii, organization_3, []],
              [call_center, :view_reports, organization_3, []],
              [call_center, :manage_overdue_list, organization_3, []]
            ]
          }

          it "returns the protocol_drugs an admin can perform actions on with organization access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create!(resource: current_resource)
              expect(admin.accessible_protocol_drugs(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_protocol_drugs(action))
              admin.accesses.delete_all
            end
          end
        end

        context "Facility Group access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, facility_group_1, []],
              [manager, :view_pii, facility_group_1, []],
              [manager, :view_reports, facility_group_1, []],
              [manager, :manage_overdue_list, facility_group_1, []],

              [viewer_all, :manage, facility_group_1, []],
              [viewer_all, :view_pii, facility_group_1, []],
              [viewer_all, :view_reports, facility_group_1, []],
              [viewer_all, :manage_overdue_list, facility_group_1, []],

              [viewer_reports_only, :manage, facility_group_1, []],
              [viewer_reports_only, :view_pii, facility_group_1, []],
              [viewer_reports_only, :view_reports, facility_group_1, []],
              [viewer_reports_only, :manage_overdue_list, facility_group_1, []],

              [call_center, :manage, facility_group_1, []],
              [call_center, :view_pii, facility_group_1, []],
              [call_center, :view_reports, facility_group_1, []],
              [call_center, :manage_overdue_list, facility_group_1, []]
            ]
          }

          it "returns the protocol_drugs an admin can perform actions on with facility group access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create!(resource: current_resource)
              expect(admin.accessible_protocol_drugs(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_protocol_drugs(action))
              admin.accesses.delete_all
            end
          end
        end

        context "Facility access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, facility_5, []],
              [manager, :view_pii, facility_5, []],
              [manager, :view_reports, facility_5, []],
              [manager, :manage_overdue_list, facility_5, []],

              [viewer_all, :manage, facility_5, []],
              [viewer_all, :view_pii, facility_5, []],
              [viewer_all, :view_reports, facility_5, []],
              [viewer_all, :manage_overdue_list, facility_5, []],

              [viewer_reports_only, :manage, facility_5, []],
              [viewer_reports_only, :view_pii, facility_5, []],
              [viewer_reports_only, :view_reports, facility_5, []],
              [viewer_reports_only, :manage_overdue_list, facility_5, []],

              [call_center, :manage, facility_5, []],
              [call_center, :view_pii, facility_5, []],
              [call_center, :view_reports, facility_5, []],
              [call_center, :manage_overdue_list, facility_5, []]
            ]
          }

          it "returns the protocol_drugs an admin can perform actions on with facility access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create!(resource: current_resource)
              expect(admin.accessible_protocol_drugs(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_protocol_drugs(action))
              admin.accesses.delete_all
            end
          end
        end
      end

      context "#accessible_admins" do
        context "Organization access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, organization_3, [manager, admin_3, admin_4]],
              [manager, :view_pii, organization_3, []],
              [manager, :view_reports, organization_3, []],
              [manager, :manage_overdue_list, organization_3, []],

              [viewer_all, :manage, organization_3, []],
              [viewer_all, :view_pii, organization_3, []],
              [viewer_all, :view_reports, organization_3, []],
              [viewer_all, :manage_overdue_list, organization_3, []],

              [viewer_reports_only, :manage, organization_3, []],
              [viewer_reports_only, :view_pii, organization_3, []],
              [viewer_reports_only, :view_reports, organization_3, []],
              [viewer_reports_only, :manage_overdue_list, organization_3, []],

              [call_center, :manage, organization_3, []],
              [call_center, :view_pii, organization_3, []],
              [call_center, :view_reports, organization_3, []],
              [call_center, :manage_overdue_list, organization_3, []]
            ]
          }

          it "returns the admins an admin can perform actions on with organization access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create!(resource: current_resource)

              row = [admin.full_name, action, current_resource.slug, expected_resources.map(&:full_name)]
              expect(admin.accessible_admins(action)).to match_array(expected_resources),
                "Failure in row: #{row}\n" + error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_admins(action))
              admin.accesses.delete_all
            end
          end
        end

        context "Facility Group access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, facility_group_1, [manager, admin_1, admin_2]],
              [manager, :view_pii, facility_group_1, []],
              [manager, :view_reports, facility_group_1, []],
              [manager, :manage_overdue_list, facility_group_1, []],

              [viewer_all, :manage, facility_group_1, []],
              [viewer_all, :view_pii, facility_group_1, []],
              [viewer_all, :view_reports, facility_group_1, []],
              [viewer_all, :manage_overdue_list, facility_group_1, []],

              [viewer_reports_only, :manage, facility_group_1, []],
              [viewer_reports_only, :view_pii, facility_group_1, []],
              [viewer_reports_only, :view_reports, facility_group_1, []],
              [viewer_reports_only, :manage_overdue_list, facility_group_1, []],

              [call_center, :manage, facility_group_1, []],
              [call_center, :view_pii, facility_group_1, []],
              [call_center, :view_reports, facility_group_1, []],
              [call_center, :manage_overdue_list, facility_group_1, []]
            ]
          }

          it "returns the admins an admin can perform actions on with facility group access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create!(resource: current_resource)

              row = [admin.full_name, action, current_resource.slug, expected_resources.map(&:full_name)]
              expect(admin.accessible_admins(action)).to match_array(expected_resources),
                "Failure in row: #{row}\n" + error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_admins(action))
              admin.accesses.delete_all
            end
          end
        end

        context "Facility access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, facility_4, [manager, admin_3, admin_4]],
              [manager, :view_pii, facility_4, []],
              [manager, :view_reports, facility_4, []],
              [manager, :manage_overdue_list, facility_4, []],

              [viewer_all, :manage, facility_4, []],
              [viewer_all, :view_pii, facility_4, []],
              [viewer_all, :view_reports, facility_4, []],
              [viewer_all, :manage_overdue_list, facility_4, []],

              [viewer_reports_only, :manage, facility_4, []],
              [viewer_reports_only, :view_pii, facility_4, []],
              [viewer_reports_only, :view_reports, facility_4, []],
              [viewer_reports_only, :manage_overdue_list, facility_4, []],

              [call_center, :manage, facility_4, []],
              [call_center, :view_pii, facility_4, []],
              [call_center, :view_reports, facility_4, []],
              [call_center, :manage_overdue_list, facility_4, []]
            ]
          }

          it "returns the admins an admin can perform actions on with facility access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create!(resource: current_resource)

              expect(admin.accessible_admins(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_admins(action))
              admin.accesses.delete_all
            end
          end
        end
      end
    end

    context "power users" do
      let!(:power_user) { create(:admin, :power_user) }

      context "#accessible_organizations" do
        let!(:permission_matrix) {
          [
            [power_user, :manage, Organization.all],
            [power_user, :view_pii, Organization.all],
            [power_user, :view_reports, Organization.all],
            [power_user, :manage_overdue_list, Organization.all]
          ]
        }

        it "returns the organizations a power user has access to" do
          permission_matrix.each do |admin, action, expected_resources|
            expect(admin.accessible_organizations(action)).to match_array(expected_resources),
              error_message(admin,
                action,
                expected_resources,
                admin.accessible_organizations(action))
          end
        end
      end

      context "#accessible_facility_groups" do
        let!(:permission_matrix) {
          [
            [power_user, :manage, FacilityGroup.all],
            [power_user, :view_pii, FacilityGroup.all],
            [power_user, :view_reports, FacilityGroup.all],
            [power_user, :manage_overdue_list, FacilityGroup.all]
          ]
        }

        it "returns the facility groups a power user has access to" do
          permission_matrix.each do |admin, action, expected_resources|
            expect(admin.accessible_facility_groups(action)).to match_array(expected_resources),
              error_message(admin,
                action,
                expected_resources,
                admin.accessible_facility_groups(action))
          end
        end
      end

      context "#accessible_facilities" do
        let!(:permission_matrix) {
          [
            [power_user, :manage, Facility.all],
            [power_user, :view_pii, Facility.all],
            [power_user, :view_reports, Facility.all],
            [power_user, :manage_overdue_list, Facility.all]
          ]
        }

        it "returns the facilities a power user has access to" do
          permission_matrix.each do |admin, action, expected_resources|
            expect(admin.accessible_facilities(action)).to match_array(expected_resources),
              error_message(admin,
                action,
                expected_resources,
                admin.accessible_facilities(action))
          end
        end
      end

      context "#accessible_users" do
        let!(:permission_matrix) {
          [
            [power_user, :manage, User.non_admins.all],
            [power_user, :view_pii, User.non_admins.all],
            [power_user, :view_reports, User.non_admins.all],
            [power_user, :manage_overdue_list, []]
          ]
        }

        it "returns the users a power user has access to" do
          permission_matrix.each do |admin, action, expected_resources|
            expect(admin.accessible_users(action)).to match_array(expected_resources),
              error_message(admin,
                action,
                expected_resources,
                admin.accessible_users(action))
          end
        end
      end

      context "#accessible_admins" do
        let!(:permission_matrix) {
          [
            [power_user, :manage, User.admins.all],
            [power_user, :view_pii, []],
            [power_user, :view_reports, []],
            [power_user, :manage_overdue_list, []]
          ]
        }

        it "returns the admins a power user has access to" do
          permission_matrix.each do |admin, action, expected_resources|
            expect(admin.accessible_admins(action)).to match_array(expected_resources),
              error_message(admin,
                action,
                expected_resources,
                admin.accessible_admins(action))
          end
        end
      end

      context "#accessible_protocols" do
        let!(:permission_matrix) {
          [
            [power_user, :manage, Protocol.all],
            [power_user, :view_pii, []],
            [power_user, :view_reports, []],
            [power_user, :manage_overdue_list, []]
          ]
        }

        it "returns the protocols a power user has access to" do
          permission_matrix.each do |admin, action, expected_resources|
            expect(admin.accessible_protocols(action)).to match_array(expected_resources),
              error_message(admin,
                action,
                expected_resources,
                admin.accessible_protocols(action))
          end
        end
      end

      context "#accessible_protocol_drugs" do
        let!(:permission_matrix) {
          [
            [power_user, :manage, ProtocolDrug.all],
            [power_user, :view_pii, []],
            [power_user, :view_reports, []],
            [power_user, :manage_overdue_list, []]
          ]
        }

        it "returns the protocol_drugs a power user has access to" do
          permission_matrix.each do |admin, action, expected_resources|
            expect(admin.accessible_protocol_drugs(action)).to match_array(expected_resources),
              error_message(admin,
                action,
                expected_resources,
                admin.accessible_protocol_drugs(action))
          end
        end
      end
    end

    def error_message(admin, action, expected, got)
      <<~MESSAGE
        access_level: #{admin.access_level}
        action: #{action}
        expected: #{expected}
        got: #{got.to_a}
      MESSAGE
    end
  end

  describe "#grant_access" do
    let!(:organization_1) { create(:organization) }
    let!(:organization_2) { create(:organization) }
    let!(:facility_group_1) { create(:facility_group, organization: organization_1) }
    let!(:facility_group_2) { create(:facility_group, organization: organization_2) }
    let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
    let!(:facility_2) { create(:facility, facility_group: facility_group_1) }
    let!(:facility_3) { create(:facility, facility_group: facility_group_2) }
    let!(:facility_4) { create(:facility) }

    let!(:viewer_access) { create(:access, user: viewer_all.user, resource: organization_1) }
    let!(:manager_access) {
      [
        create(:access, user: manager.user, resource: organization_1),
        create(:access, user: manager.user, resource: facility_group_2),
        create(:access, user: manager.user, resource: facility_4)
      ]
    }

    it "raises an error if the access level of the new user is not grantable by the current user" do
      new_user = create(:admin, :manager)

      expect {
        viewer_all.grant_access(new_user, [facility_1.id, facility_2.id])
      }.to raise_error(UserAccess::NotAuthorizedError)
    end

    it "raises an error if the user could not provide any access" do
      new_user = create(:admin, :viewer_all)
      selected_facility = create(:facility).id

      expect {
        manager.grant_access(new_user, [selected_facility])
      }.to raise_error(UserAccess::NotAuthorizedError)
    end

    it "only grants access to the selected facilities" do
      new_user = create(:admin, :viewer_all)

      manager.grant_access(new_user, [facility_1.id, facility_2.id])

      expect(new_user.reload.accessible_facilities(:view_pii)).to contain_exactly(facility_1, facility_2)
    end

    it "skips granting access to any resource if no facilities are selected" do
      new_user = create(:admin, :viewer_all)

      expect(manager.grant_access(new_user, [])).to be_nil
    end

    context "grantee is power_user" do
      it "only allows power users to grant access" do
        new_user = create(:admin, :power_user)

        expect(power_user.grant_access(new_user, [facility_1.id, facility_2.id])).to be_nil

        expect {
          manager.grant_access(new_user, [facility_1.id, facility_2.id])
        }.to raise_error(UserAccess::NotAuthorizedError)
      end

      it "skips granting access to any resource" do
        new_user = create(:admin, :power_user)

        expect(new_user.reload.accesses).to be_empty
      end
    end

    context "promote access" do
      it "promotes to FacilityGroup access" do
        new_user = create(:admin, :viewer_all)

        manager.grant_access(new_user, [facility_3.id])
        expected_access_resources = %w[FacilityGroup]

        expect(new_user.reload.accesses.map(&:resource_type)).to match_array(expected_access_resources)
      end

      it "promotes to Organization access" do
        new_user = create(:admin, :manager)

        manager.grant_access(new_user, [facility_1.id, facility_2.id])
        expected_access_resources = %w[Organization]

        expect(new_user.reload.accesses.map(&:resource_type)).to match_array(expected_access_resources)
      end

      it "gives access to individual facilities that cannot be promoted" do
        new_user = create(:admin, :manager)

        manager.grant_access(new_user, [facility_1.id, facility_2.id, facility_4.id])
        expected_access_resources = %w[Organization Facility]

        expect(new_user.reload.accesses.map(&:resource_type)).to match_array(expected_access_resources)
      end
    end

    context "allows editing accesses" do
      it "removes access" do
        new_user = create(:admin, :manager)

        manager.grant_access(new_user, [facility_1.id, facility_2.id, facility_4.id])
        expected_access_resources = %w[Organization Facility]

        expect(new_user.reload.accesses.map(&:resource_type)).to match_array(expected_access_resources)

        manager.grant_access(new_user, [facility_1.id, facility_2.id])
        expected_access_resources = %w[Organization]

        expect(new_user.reload.accesses.map(&:resource_type)).to match_array(expected_access_resources)
      end

      it "adds new access" do
        new_user = create(:admin, :manager)

        manager.grant_access(new_user, [facility_1.id, facility_2.id])
        expected_access_resources = %w[Organization]

        expect(new_user.reload.accesses.map(&:resource_type)).to match_array(expected_access_resources)

        manager.grant_access(new_user, [facility_1.id, facility_2.id, facility_4.id])
        expected_access_resources = %w[Organization Facility]

        expect(new_user.reload.accesses.map(&:resource_type)).to match_array(expected_access_resources)
      end
    end
  end

  describe "#permitted_access_levels" do
    let!(:access_level_matrix) {
      [
        [:power_user, UserAccess::LEVELS.keys],
        [:manager, [:call_center, :manager, :viewer_all, :viewer_reports_only]],
        [:viewer_all, []],
        [:viewer_reports_only, []],
        [:call_center, []]
      ]
    }

    it "returns the access levels the current admin can grant to another admin" do
      access_level_matrix.each do |access_level, permitted_access_levels|
        admin = create(:admin, access_level)

        expect(admin.permitted_access_levels).to match_array(permitted_access_levels),
          <<~ERROR
            for admin with: #{access_level}
            expected: #{permitted_access_levels}
            got: #{admin.permitted_access_levels}
          ERROR
      end
    end
  end
end
