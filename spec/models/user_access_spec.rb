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

    let!(:manager) { UserAccess.new(create(:admin, :manager)) }
    let!(:viewer_all) { UserAccess.new(create(:admin, :viewer_all)) }
    let!(:viewer_reports_only) { UserAccess.new(create(:admin, :viewer_reports_only)) }
    let!(:call_center) { UserAccess.new(create(:admin, :call_center)) }

    let!(:admins) { [manager, viewer_all, viewer_reports_only, call_center] }
    let!(:actions) { described_class::ACTION_TO_LEVEL.keys }

    context "non power users" do
      context "#accessible_organizations" do
        it "returns the organizations an admin has access to" do
          # Grant Accesses
          admins.each do |admin|
            admin.user.accesses.create(resource: organization_3)
          end

          admins.each do |admin|
            actions.each do |action|
              if described_class::ACTION_TO_LEVEL[action].include?(admin.user.access_level.to_sym)
                expect(admin.accessible_organizations(action)).to contain_exactly(organization_3)
              else
                expect(admin.accessible_organizations(action)).to match_array([])
              end
            end
          end
        end
      end

      context "#accessible_facility_groups" do
        context "organization access" do
          it "returns the facility groups an admin has access to" do
            # Grant Accesses
            admins.each do |admin|
              admin.user.accesses.create(resource: organization_3)
            end

            admins.each do |admin|
              actions.each do |action|
                if described_class::ACTION_TO_LEVEL[action].include?(admin.user.access_level.to_sym)
                  expect(admin.accessible_facility_groups(action)).to contain_exactly(facility_group_3_1, facility_group_3_2)
                else
                  expect(admin.accessible_facility_groups(action)).to match_array([])
                end
              end
            end
          end
        end

        context "facility group access"
        it "returns the facility groups an admin has access to" do
          # Grant Accesses
          admins.each do |admin|
            admin.user.accesses.create(resource: facility_group_1)
          end

          admins.each do |admin|
            actions.each do |action|
              if described_class::ACTION_TO_LEVEL[action].include?(admin.user.access_level.to_sym)
                expect(admin.accessible_facility_groups(action)).to contain_exactly(facility_group_1)
              else
                expect(admin.accessible_facility_groups(action)).to match_array([])
              end
            end
          end
        end
      end

      context "#accessible_facilities" do
        context "organization access" do
          it "returns the facilities an admin has access to" do
            # Grant Accesses
            admins.each do |admin|
              admin.user.accesses.create(resource: organization_3)
            end

            admins.each do |admin|
              actions.each do |action|
                if described_class::ACTION_TO_LEVEL[action].include?(admin.user.access_level.to_sym)
                  expect(admin.accessible_facilities(action)).to contain_exactly(facility_3, facility_4)
                else
                  expect(admin.accessible_facilities(action)).to match_array([])
                end
              end
            end
          end
        end

        context "facility group access"
        it "returns the facilities an admin has access to" do
          # Grant Accesses
          admins.each do |admin|
            admin.user.accesses.create(resource: facility_group_1)
          end

          admins.each do |admin|
            actions.each do |action|
              if described_class::ACTION_TO_LEVEL[action].include?(admin.user.access_level.to_sym)
                expect(admin.accessible_facilities(action)).to contain_exactly(facility_1)
              else
                expect(admin.accessible_facilities(action)).to match_array([])
              end
            end
          end
        end

        context "facility access"
        it "returns the facilities an admin has access to" do
          # Grant Accesses
          admins.each do |admin|
            admin.user.accesses.create(resource: facility_5)
          end

          admins.each do |admin|
            actions.each do |action|
              if described_class::ACTION_TO_LEVEL[action].include?(admin.user.access_level.to_sym)
                expect(admin.accessible_facilities(action)).to contain_exactly(facility_5)
              else
                expect(admin.accessible_facilities(action)).to match_array([])
              end
            end
          end
        end
      end

      context "#accessible_users" do
        context "organization access" do
          it "returns the users an admin can manage" do
            # Grant Accesses
            admins.each do |admin|
              admin.user.accesses.create(resource: organization_3)
            end

            admins.each do |admin|
              actions.each do |action|
                if action == :manage && described_class::ACTION_TO_LEVEL[action].include?(admin.user.access_level.to_sym)
                  expect(admin.accessible_users(action)).to contain_exactly(user_3, user_4)
                else
                  expect(admin.accessible_users(action)).to match_array([])
                end
              end
            end
          end
        end

        context "facility group access"
        it "returns the users an admin can manage" do
          # Grant Accesses
          admins.each do |admin|
            admin.user.accesses.create(resource: facility_group_1)
          end

          admins.each do |admin|
            actions.each do |action|
              if action == :manage && described_class::ACTION_TO_LEVEL[action].include?(admin.user.access_level.to_sym)
                expect(admin.accessible_users(action)).to contain_exactly(user_1)
              else
                expect(admin.accessible_users(action)).to match_array([])
              end
            end
          end
        end

        context "facility access"
        it "returns the users an admin can manage" do
          # Grant Accesses
          admins.each do |admin|
            admin.user.accesses.create(resource: facility_5)
          end

          admins.each do |admin|
            actions.each do |action|
              if action == :manage && described_class::ACTION_TO_LEVEL[action].include?(admin.user.access_level.to_sym)
                expect(admin.accessible_users(action)).to contain_exactly(user_5)
              else
                expect(admin.accessible_users(action)).to match_array([])
              end
            end
          end
        end
      end

      context "#accessible_admins" do
        context "organization access" do
          it "returns the admins an admin can manage" do
            # Grant Accesses, and set Organization
            admins.each do |admin|
              admin.user.update!(organization: organization_3)
              admin.user.accesses.create(resource: organization_3)
            end

            admins.each do |admin|
              actions.each do |action|
                if action == :manage && described_class::ACTION_TO_LEVEL[action].include?(admin.user.access_level.to_sym)
                  expect(admin.accessible_admins(action)).to match_array(User.admins.where(organization: admin.user.organization))
                else
                  expect(admin.accessible_admins(action)).to match_array([])
                end
              end
            end
          end
        end

        context "facility group access"
        it "returns the admins an admin can manage" do
          # Grant Accesses, and set Organization
          admins.each do |admin|
            admin.user.update!(organization: organization_1)
            admin.user.accesses.create(resource: facility_group_1)
          end

          admins.each do |admin|
            actions.each do |action|
              if action == :manage && described_class::ACTION_TO_LEVEL[action].include?(admin.user.access_level.to_sym)
                expect(admin.accessible_admins(action)).to match_array(User.admins.where(organization: admin.user.organization))
              else
                expect(admin.accessible_admins(action)).to match_array([])
              end
            end
          end
        end

        context "facility access"
        it "returns the admins an admin can manage" do
          # Grant Accesses, and set Organization
          admins.each do |admin|
            admin.user.update!(organization: organization_3)
            admin.user.accesses.create(resource: facility_4)
          end

          admins.each do |admin|
            actions.each do |action|
              if action == :manage && described_class::ACTION_TO_LEVEL[action].include?(admin.user.access_level.to_sym)
                expect(admin.accessible_admins(action)).to match_array(User.admins.where(organization: admin.user.organization))
              else
                expect(admin.accessible_admins(action)).to match_array([])
              end
            end
          end
        end
      end
    end

    context "power users" do
      let!(:power_user) { UserAccess.new(create(:admin, :power_user)) }

      context "#accessible_organizations" do
        it "returns the organizations an admin has access to" do
          actions.each do |action|
            expect(power_user.accessible_organizations(action)).to match_array(Organization.all)
          end
        end
      end

      context "#accessible_facility_groups" do
        it "returns the facilities an admin has access to" do
          actions.each do |action|
            expect(power_user.accessible_facility_groups(action)).to match_array(FacilityGroup.all)
          end
        end
      end

      context "#accessible_facilities" do
        it "returns the facilities an admin has access to" do
          actions.each do |action|
            expect(power_user.accessible_facilities(action)).to match_array(Facility.all)
          end
        end
      end

      context "#accessible_users" do
        it "returns the users an admin can manage" do
          actions.each do |action|
            expect(power_user.accessible_users(action)).to match_array(User.non_admins.all)
          end
        end
      end

      context "#accessible_admins" do
        it "returns the admins an admin can manage" do
          actions.each do |action|
            expect(power_user.accessible_admins(action)).to match_array(User.admins.all)
          end
        end
      end
    end
  end
end
