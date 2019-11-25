require "rails_helper"

RSpec.describe Manage::Admin::UserPolicy do
  subject { described_class }
  let(:organization1) { create(:organization) }
  let(:organization2) { create(:organization) }

  let(:admin1) { create(:admin, organization: organization1) }
  let(:admin2) { create(:admin, organization: organization2) }

  let(:user) { create(:admin) }

  context 'user has permission to manage admins for all organizations' do
    let!(:permission) { create(:user_permission, user: user, permission_slug: :manage_admins) }

    permissions :index?, :new? do
      it 'allows the user' do
        expect(subject).to permit(user, User)
      end
    end

    permissions :show?, :create?, :update?, :edit?, :destroy? do
      it 'allows the user' do
        expect(subject).to permit(user, admin1)
        expect(subject).to permit(user, admin2)
      end
    end
  end

  context 'user has permission to manage admin for a given organization' do
    let!(:permission) { create(:user_permission, user: user, permission_slug: :manage_admins, resource: organization1) }

    permissions :index?, :new? do
      it 'allows the user' do
        expect(subject).to permit(user, User)
      end
    end

    permissions :show?, :create?, :update?, :edit?, :destroy? do
      it 'allows the user for admins in their organization' do
        expect(subject).to permit(user, admin1)
      end
    end

    permissions :show?, :create?, :update?, :edit?, :destroy? do
      it 'denies the user for admins outside their organization' do
        expect(subject).not_to permit(user, admin2)
      end
    end
  end

  context 'user does not have permission to manage admins' do
    let(:other_permissions) { Permissions::ALL_PERMISSIONS.keys - [:manage_admins] }

    before do
      other_permissions.each do |slug| 
        user.user_permissions.create(permission_slug: slug)
      end
    end

    permissions :index?, :new? do
      it 'allows the user' do
        expect(subject).not_to permit(user, User)
      end
    end

    permissions :show?, :create?, :update?, :edit?, :destroy? do
      it 'allows the user for admins in their organization' do
        expect(subject).not_to permit(user, admin1)
      end
    end

    permissions :show?, :create?, :update?, :edit?, :destroy? do
      it 'denies the user for admins outside their organization' do
        expect(subject).not_to permit(user, admin2)
      end
    end
  end

  describe '#allowed_permissions' do
    let(:user_permission_slugs) { Permissions::ALL_PERMISSIONS.keys.shuffle.take(10) }
    let!(:permissions) do
      user_permission_slugs.each do |permission_slug|
        user.user_permissions.create(permission_slug: permission_slug)
      end
    end

    it 'includes all the permissions the user can access' do
      allowed_permissions = subject.new(user, nil).allowed_permissions
      expect(allowed_permissions.map { |permission| permission[:slug] })
        .to match_array(user_permission_slugs)
    end

    it 'does not include other permissions' do
      allowed_permissions = subject.new(user, nil).allowed_permissions
      expect(allowed_permissions.map { |permission| permission[:slug] })
        .not_to include(*(Permissions::ALL_PERMISSIONS.keys - user_permission_slugs))
    end
  end

  describe '#allowed_access_levels' do
    let(:user_permission_slugs) { Permissions::ALL_PERMISSIONS.keys.shuffle.take(5) }
    let!(:permissions) do
      user_permission_slugs.each do |permission_slug|
        user.user_permissions.create(permission_slug: permission_slug)
      end
    end

    let(:expected_access_levels) do
      Permissions::ACCESS_LEVELS.select do |access_level|
        access_level[:default_permissions].to_set.subset?(user_permission_slugs.to_set)
      end
    end

    let(:disallowed_access_levels) do
      Permissions::ACCESS_LEVELS - expected_access_levels
    end

    it 'includes access levels whose default permissions are a subset of allowed permissions' do
      allowed_access_levels = subject.new(user, nil).allowed_access_levels
      expect(allowed_access_levels).to match_array(expected_access_levels)
    end

    it 'does not include access levels whose default permissions are not a subset of allowed permissions' do
      allowed_access_levels = subject.new(user, nil).allowed_access_levels
      expect(allowed_access_levels).not_to include(disallowed_access_levels)
    end
  end
end

RSpec.describe Manage::Admin::UserPolicy::Scope do
  subject { described_class }
  let(:organization1) { create(:organization) }
  let(:organization2) { create(:organization) }

  let(:admin1) { create(:admin, organization: organization1) }
  let(:admin2) { create(:admin, organization: organization2) }

  let(:user) { create(:admin) }

  context 'user has permission to manage admins for all organizations' do
    let!(:permission) { create(:user_permission, user: user, permission_slug: :manage_admins) }
    it 'resolves all users with email authentications' do
      resolved_records = subject.new(user, User.all).resolve
      expect(resolved_records).to match_array([user, admin1, admin2])
    end
  end

  context 'user has permission to manage admin for a given organization' do
    let!(:permission) { create(:user_permission, user: user, permission_slug: :manage_admins, resource: organization1) }
    it 'resolves all users with email authentications in that organization' do
      resolved_records = subject.new(user, User.all).resolve
      expect(resolved_records).to match_array([admin1])
    end
  end

  context 'user does not have permission to manage admins' do
    let(:other_permissions) { Permissions::ALL_PERMISSIONS.keys - [:manage_admins] }

    before do
      other_permissions.each do |slug|
        user.user_permissions.create(permission_slug: slug)
      end
    end

    it 'resolves empty result' do
      resolved_records = subject.new(user, User.all).resolve
      expect(resolved_records).to be_empty
    end
  end
end
