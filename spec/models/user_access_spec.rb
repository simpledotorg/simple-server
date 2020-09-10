require "rails_helper"

RSpec.describe UserAccess, type: :model do
  let(:viewer_all) { UserAccess.new(create(:admin, :viewer_all)) }
  let(:manager) { UserAccess.new(create(:admin, :manager)) }

  describe "#grant_access" do
    let!(:organization_1) { create(:organization) }
    let!(:organization_2) { create(:organization) }
    let!(:facility_group_1) { create(:facility_group, organization: organization_1) }
    let!(:facility_group_2) { create(:facility_group, organization: organization_2) }
    let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
    let!(:facility_2) { create(:facility, facility_group: facility_group_1) }
    let!(:facility_3) { create(:facility, facility_group: facility_group_2) }
    let!(:facility_4) { create(:facility) }
    let!(:viewer_access) {
      create(:access, user: viewer_all.user, resource: organization_1)
    }
    let!(:manager_access) {
      [create(:access, user: manager.user, resource: organization_1),
        create(:access, user: manager.user, resource: facility_group_2),
        create(:access, user: manager.user, resource: facility_4)]
    }

    it "raises an error if the access level of the new user is not grantable by the current" do
      new_user = create(:admin, :manager)

      expect {
        viewer_all.grant_access(new_user, [facility_1.id, facility_2.id])
      }.to raise_error(UserAccess::NotAuthorizedError)
    end

    it "raises an error if the user could not provide any access" do
      new_user = create(:admin, :viewer_all)

      expect {
        manager.grant_access(new_user, [create(:facility).id])
      }.to raise_error(UserAccess::NotAuthorizedError)
    end

    it "only grants access to the selected facilities" do
      new_user = create(:admin, :viewer_all)

      manager.grant_access(new_user, [facility_1.id, facility_2.id])

      expect(new_user.reload.accessible_facilities(:view_pii)).to contain_exactly(facility_1, facility_2)
    end

    it "returns nothing if no facilities are selected" do
      new_user = create(:admin, :viewer_all)
      expect(manager.grant_access(new_user, [])).to be_nil
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

  pending "#access_tree" do
    let!(:organization_1) { create(:organization) }
    let!(:organization_2) { create(:organization) }
    let!(:organization_3) { create(:organization) }
    let!(:facility_group_1) { create(:facility_group, organization: organization_1) }
    let!(:facility_group_2) { create(:facility_group, organization: organization_2) }
    let!(:facility_group_3) { create(:facility_group, organization: organization_3) }
    let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
    let!(:facility_2) { create(:facility, facility_group: facility_group_1) }
    let!(:facility_3) { create(:facility, facility_group: facility_group_2) }
    let!(:facility_4) { create(:facility, facility_group: facility_group_3) }
    let!(:viewer_access) {
      create(:access, user: viewer_all.user, resource: organization_1)
    }
    let!(:manager_access) {
      create(:access, user: manager.user, resource: organization_1)
      create(:access, user: manager.user, resource: facility_3)
    }

    context "render a nested data structure" do
      it "only allows the direct parent or ancestors to be in the tree" do
        expected_access_tree = {
          organizations: {
            organization_1 => {
              can_access: true,
              total_facility_groups: 1,

              facility_groups: {
                facility_group_1 => {
                  can_access: true,
                  total_facilities: 2,

                  facilities: {
                    facility_1 => {
                      can_access: true
                    },

                    facility_2 => {
                      can_access: true
                    }
                  }
                }
              }
            }
          }
        }

        expect(viewer_all.access_tree(:view_pii)).to eq(expected_access_tree)
        expect(viewer_all.access_tree(:manage)).to eq(organizations: {})
      end

      it "marks the direct parents or ancestors as inaccessible if the access is partial" do
        expected_access_tree = {
          organizations: {
            organization_1 => {
              can_access: true,
              total_facility_groups: 1,

              facility_groups: {
                facility_group_1 => {
                  can_access: true,
                  total_facilities: 2,

                  facilities: {
                    facility_1 => {
                      can_access: true
                    },

                    facility_2 => {
                      can_access: true
                    }
                  }
                }
              }
            },

            organization_2 => {
              can_access: false,
              total_facility_groups: 1,

              facility_groups: {
                facility_group_2 => {
                  can_access: false,
                  total_facilities: 1,

                  facilities: {
                    facility_3 => {
                      can_access: true
                    }
                  }
                }
              }
            }
          }
        }

        expect(manager.access_tree(:view_pii)).to eq(expected_access_tree)
        expect(manager.access_tree(:manage)).to eq(expected_access_tree)
      end
    end
  end

  describe "#permitted_access_levels" do
    specify do
      power_user = create(:admin, :power_user)
      expect(power_user.permitted_access_levels).to match_array(UserAccess::LEVELS.keys)
    end

    specify do
      manager = create(:admin, :manager)
      expect(manager.permitted_access_levels).to match_array([:call_center, :manager, :viewer_all, :viewer_reports_only])
    end

    specify do
      viewer_all = create(:admin, :viewer_all)
      expect(viewer_all.permitted_access_levels).to match_array([])
    end

    specify do
      manager = create(:admin, :viewer_reports_only)
      expect(manager.permitted_access_levels).to match_array([])
    end

    specify do
      manager = create(:admin, :call_center)
      expect(manager.permitted_access_levels).to match_array([])
    end
  end

  context "accessible_*" do
    let!(:organization_1) { create(:organization) }
    let!(:organization_2) { create(:organization) }
    let!(:organization_3) { create(:organization) }

    let!(:facility_group_1) { create(:facility_group, organization: organization_1) }
    let!(:facility_group_2) { create(:facility_group, organization: organization_2) }
    let!(:facility_group_3_1) { create(:facility_group, organization: organization_3) }
    let!(:facility_group_3_2) { create(:facility_group, organization: organization_3) }

    let!(:facility_1) { create(:facility, facility_group: facility_group_1) }
    let!(:facility_2) { create(:facility, facility_group: facility_group_2) }
    let!(:facility_3) { create(:facility, facility_group: facility_group_3_1) }
    let!(:facility_4) { create(:facility, facility_group: facility_group_3_2) }
    let!(:facility_5) { create(:facility) }
    let!(:facility_6) { create(:facility) }

    let!(:user_1) { create(:user, :with_phone_number_authentication, registration_facility: facility_1) }
    let!(:user_2) { create(:user, :with_phone_number_authentication, registration_facility: facility_2) }
    let!(:user_3) { create(:user, :with_phone_number_authentication, registration_facility: facility_3) }
    let!(:user_4) { create(:user, :with_phone_number_authentication, registration_facility: facility_4) }
    let!(:user_5) { create(:user, :with_phone_number_authentication, registration_facility: facility_5) }

    let!(:admin_1) { create(:admin, :call_center, organization: organization_1) }
    let!(:admin_2) { create(:admin, :call_center, organization: organization_1) }
    let!(:admin_3) { create(:admin, :call_center, organization: organization_3) }
    let!(:admin_4) { create(:admin, :call_center, organization: organization_3) }
    let!(:admin_5) { create(:admin, :call_center) }

    let!(:manager) { create(:admin, :manager) }
    let!(:viewer_all) { create(:admin, :viewer_all) }
    let!(:viewer_reports_only) { create(:admin, :viewer_reports_only) }
    let!(:call_center) { create(:admin, :call_center) }

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
            admin.accesses.create(resource: current_resource)
            expect(admin.accessible_organizations(action)).to match_array(expected_resources),
              error_message(admin,
                action,
                expected_resources,
                admin.accessible_organizations(action))
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
              admin.accesses.create(resource: current_resource)
              expect(admin.accessible_facility_groups(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_facility_groups(action))
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
              admin.accesses.create(resource: current_resource)
              expect(admin.accessible_facility_groups(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_facility_groups(action))
            end
          end
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
              admin.accesses.create(resource: current_resource)
              expect(admin.accessible_facilities(action)).to match_array(expected_resources)
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
              admin.accesses.create(resource: current_resource)
              expect(admin.accessible_facilities(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_facilities(action))
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

          it "returns the facilities an admin can perform actions on with facility access" do
            permission_matrix.each do |admin, action, current_resource, expected_resources|
              admin.accesses.create(resource: current_resource)
              expect(admin.accessible_facilities(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_facilities(action))
            end
          end
        end
      end

      context "#accessible_users" do
        context "Organization access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, organization_3, [user_3, user_4]],
              [manager, :view_pii, organization_3, []],
              [manager, :view_reports, organization_3, [user_3, user_4]],
              [manager, :manage_overdue_list, organization_3, []],

              [viewer_all, :manage, organization_3, []],
              [viewer_all, :view_pii, organization_3, []],
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
              admin.accesses.create(resource: current_resource)
              expect(admin.accessible_users(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_users(action))
            end
          end
        end

        context "Facility Group access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, facility_group_1, [user_1]],
              [manager, :view_pii, facility_group_1, []],
              [manager, :view_reports, facility_group_1, [user_1]],
              [manager, :manage_overdue_list, facility_group_1, []],

              [viewer_all, :manage, facility_group_1, []],
              [viewer_all, :view_pii, facility_group_1, []],
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
              admin.accesses.create(resource: current_resource)
              expect(admin.accessible_users(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_users(action))
            end
          end
        end

        context "Facility access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, facility_5, [user_5]],
              [manager, :view_pii, facility_5, []],
              [manager, :view_reports, facility_5, [user_5]],
              [manager, :manage_overdue_list, facility_5, []],

              [viewer_all, :manage, facility_5, []],
              [viewer_all, :view_pii, facility_5, []],
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
              admin.accesses.create(resource: current_resource)
              expect(admin.accessible_users(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_users(action))
            end
          end
        end
      end

      context "#accessible_admins" do
        context "Organization access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, organization_3, User.admins.where(organization: organization_3)],
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
              admin.update(organization: organization_3)
              admin.accesses.create(resource: current_resource)
              expect(admin.accessible_admins(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_admins(action))
            end
          end
        end

        context "Facility Group access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, facility_group_1, User.admins.where(organization: organization_1)],
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
              admin.update(organization: organization_1)
              admin.accesses.create(resource: current_resource)
              expect(admin.accessible_admins(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_admins(action))
            end
          end
        end

        context "Facility access" do
          let!(:permission_matrix) {
            [
              [manager, :manage, facility_4, User.admins.where(organization: organization_3)],
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
              admin.update(organization: organization_3)
              admin.accesses.create(resource: current_resource)
              expect(admin.accessible_admins(action)).to match_array(expected_resources),
                error_message(admin,
                  action,
                  expected_resources,
                  admin.accessible_admins(action))
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
            [power_user, :view_pii, []],
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
    end
  end

  def error_message(admin, action, expected, got)
    "access_level: #{admin.access_level}\n"\
    "action: #{action}\n"\
    "expected: #{expected}\n"\
    "got: #{got.to_a}"
  end
end
