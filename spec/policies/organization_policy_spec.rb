require 'rails_helper'

RSpec.describe OrganizationPolicy do
  subject { described_class }

  let(:organization_1) { FactoryBot.create(:organization) }
  let(:organization_2) { FactoryBot.create(:organization) }

  let(:user_can_manage_all_organizations) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_manage_all_organizations, resource: nil)
    user
  end

  let(:user_can_manage_an_organization) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_manage_an_organization, resource: organization_1)
    user
  end

  let(:other_user) { create(:master_user) }

  permissions :index?, :new?, :create? do
    it 'permits users who can manage all organizations' do
      expect(subject).to permit(user_can_manage_all_organizations, Organization)
    end

    it 'denies other users' do
      expect(subject).not_to permit(other_user, Organization)
    end
  end

  permissions :show?, :update?, :edit? do
    it 'permits users who can manage all organizations' do
      expect(subject).to permit(user_can_manage_all_organizations, organization_1)
      expect(subject).to permit(user_can_manage_all_organizations, organization_2)
    end

    it 'permits users who have permission to manage an organization' do
      expect(subject).to permit(user_can_manage_an_organization, organization_1)
    end

    it 'denies users who have permission to manage an organization for other organizations' do
      expect(subject).not_to permit(user_can_manage_an_organization, organization_2)
    end

    it 'denies other users' do
      expect(subject).not_to permit(other_user, organization_1)
      expect(subject).not_to permit(other_user, organization_2)
    end
  end

  permissions :destroy? do
    it 'permits users with permission to manage all organizations' do
      expect(subject).to permit(user_can_manage_all_organizations, organization_1)
    end

    it 'denies other users' do
      expect(subject).not_to permit(other_user, organization_1)
    end
  end
end

RSpec.describe OrganizationPolicy::Scope do
  let(:subject) { described_class }
  let(:organization_1) { create(:organization) }
  let(:organization_2) { create(:organization) }
  let(:organization_3) { create(:organization) }

  let(:user_can_manage_all_organizations) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_manage_all_organizations, resource: nil)
    user
  end

  let(:user_can_manage_an_organization) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_manage_an_organization, resource: organization_1)
    create(:user_permission, user: user, permission_slug: :can_manage_an_organization, resource: organization_2)
    user
  end

  let(:other_user) { create(:master_user) }

  context 'user has permission to manage all organizations' do
    it 'resolves all organizations' do
      resolved_records = subject.new(user_can_manage_all_organizations, Organization.all).resolve
      expect(resolved_records.to_a).to match_array(Organization.all.to_a)
    end
  end

  context 'user has permission to manage an organizations' do
    it 'resolves to a list of organizations they have permission to manage' do
      resolved_records = subject.new(user_can_manage_an_organization, Organization.all).resolve
      expect(resolved_records.to_a).to match_array([organization_1, organization_2])
    end
  end

  context 'other users' do
    it 'resolves to an collection' do
      resolved_records = subject.new(other_user, Organization.all).resolve
      expect(resolved_records.to_a).to be_empty
    end
  end
end
