require "rails_helper"

RSpec.describe InvitationPolicy do
  subject { described_class }

  context 'user with permission to manage all users' do
    let(:user_with_permission) do
      create(:admin, user_permissions: [build(:user_permission, permission_slug: :can_manage_all_users)])
    end
    let(:organization) { create(:organization) }

    permissions :new?, :create? do
      it 'allows user to invite admins with any role' do
        User.roles.keys.each do |role|
          invited_user = build(:admin, role: role, organization: organization)
          expect(subject).to permit(user_with_permission, invited_user)
        end
      end
    end
  end

  context 'user with permission to manage users for an organization' do
    let(:organization) { create(:organization) }
    let(:user_with_permission) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :can_manage_users_for_organization, resource: organization)
      ])
    end

    permissions :new?, :create? do
      it 'allows user to invite admins with any role other than owner' do
        User.roles.except(:owner).keys.each do |role|
          invited_user = build(:admin, role: role, organization: organization)
          expect(subject).to permit(user_with_permission, invited_user)
        end
      end

      it 'denies user to invite admins with owner role' do
        invited_user = build(:admin, role: :owner, organization: organization)
        expect(subject).not_to permit(user_with_permission, invited_user)
      end
    end
  end
end