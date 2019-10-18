require "rails_helper"

RSpec.describe Manage::FacilityGroupPolicy do
  subject { described_class }

  context 'user can manage all organizations' do
    let(:user_with_permission) do
      create(:admin, user_permissions: [build(:user_permission, permission_slug: :manage_organizations)])
    end

    let(:facility_group_1) { build(:facility_group) }
    let(:facility_group_2) { build(:facility_group) }

    permissions :index? do
      it 'allows the user' do
        expect(subject).to permit(user_with_permission, FacilityGroup)
      end
    end

    permissions :show?, :new?, :create?, :edit?, :update?, :destroy? do
      it 'allows the user' do
        expect(subject).to permit(user_with_permission, facility_group_1)
        expect(subject).to permit(user_with_permission, facility_group_2)
      end
    end
  end

  context 'user can manage an organization' do
    let(:organization) { create(:organization) }
    let(:user_with_permission) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :manage_facility_groups, resource: organization)
      ])
    end

    let(:facility_group_1) { build(:facility_group, organization: organization) }
    let(:facility_group_2) { build(:facility_group) }

    permissions :index? do
      it 'allows the user' do
        expect(subject).to permit(user_with_permission, FacilityGroup)
      end
    end

    permissions :show?, :edit?, :update?, :destroy? do
      it 'allows the user for facility groups in their organization' do
        expect(subject).to permit(user_with_permission, facility_group_1)
      end

      it 'denies the user for facility groups outside their organization' do
        expect(subject).not_to permit(user_with_permission, facility_group_2)
      end
    end

    permissions :create? do
      it 'allows the user to create facility groups in their organization' do
        expect(subject).to permit(user_with_permission, facility_group_1)
      end
    end
  end
end

RSpec.describe Manage::FacilityGroupPolicy::Scope do
  let(:subject) { described_class }
  let(:organization) { create(:organization) }
  let!(:facility_group_1) { create(:facility_group, organization: organization) }
  let!(:facility_group_2) { create(:facility_group, organization: organization) }
  let!(:facility_group_3) { create(:facility_group) }

  context 'user can manage all organizations' do
    let(:user_with_permission) do
      create(:admin, user_permissions: [build(:user_permission, permission_slug: :manage_organizations)])
    end

    it 'resolve all facility groups' do
      resolved_records = subject.new(user_with_permission, FacilityGroup.all).resolve
      expect(resolved_records).to match_array(FacilityGroup.all)
    end
  end

  context 'user can manage an organization' do
    let(:user_with_permission) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :manage_facility_groups, resource: organization)
      ])
    end

    it 'resolve all facility groups in their organization' do
      resolved_records = subject.new(user_with_permission, FacilityGroup.all).resolve
      expect(resolved_records).to match_array([facility_group_1, facility_group_2])
    end
  end

  context 'other users' do
    let(:other_user) do
      create(:admin, user_permissions: [])
    end

    it 'resolves an empty set' do
      resolved_records = subject.new(other_user, FacilityGroup.all).resolve
      expect(resolved_records).to be_empty
    end
  end
end
