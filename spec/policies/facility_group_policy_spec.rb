require "rails_helper"

RSpec.describe FacilityGroupPolicy do
  subject { described_class }

  context 'user can manage all organizations' do
    let(:user_with_permission) do
      create(:user, permissions: [:can_manage_all_organizations])
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
      create(:user, permissions: [[:can_manage_an_organization, organization]])
    end

    let(:facility_group_1) { build(:facility_group, organization: organization) }
    let(:facility_group_2) { build(:facility_group) }

    permissions :index? do
      it 'allows the user' do
        expect(subject).to permit(user_with_permission, FacilityGroup)
      end
    end

    permissions :show?, :new?, :create?, :edit?, :update?, :destroy? do
      it 'allows the user for facility groups in their organization' do
        expect(subject).to permit(user_with_permission, facility_group_1)
      end

      it 'denies the user for facility groups outside their organization' do
        expect(subject).not_to permit(user_with_permission, facility_group_2)
      end
    end
  end

  context 'user can manage a facility group' do
    let(:facility_group_1) { create(:facility_group) }
    let(:facility_group_2) { create(:facility_group) }

    let(:user_with_permission) do
      create(:user, permissions: [[:can_manage_a_facility_group, facility_group_1]])
    end

    permissions :index? do
      it 'allows the user' do
        expect(subject).to permit(user_with_permission, FacilityGroup)
      end
    end

    permissions :show? do
      it 'allows the user for their facility groups' do
        expect(subject).to permit(user_with_permission, facility_group_1)
      end


      it 'denies the user for other facility groups' do
        expect(subject).not_to permit(user_with_permission, facility_group_2)
      end
    end

    permissions :new?, :create?, :edit?, :update?, :destroy? do
      it 'denies the user for their facility group' do
        expect(subject).not_to permit(user_with_permission, facility_group_1)
      end

      it 'denies the user for other facility groups' do
        expect(subject).not_to permit(user_with_permission, facility_group_2)
      end
    end
  end
end

RSpec.describe FacilityGroupPolicy::Scope do
  let(:subject) { described_class }
  let(:organization) { create(:organization) }
  let!(:facility_group_1) { create(:facility_group, organization: organization) }
  let!(:facility_group_2) { create(:facility_group, organization: organization) }
  let!(:facility_group_3) { create(:facility_group) }

  context 'user can manage all organizations' do
    let(:user_with_permission) do
      create(:user, permissions: [:can_manage_all_organizations])
    end

    it 'resolve all facility groups' do
      resolved_records = subject.new(user_with_permission, FacilityGroup.all).resolve
      expect(resolved_records).to match_array(FacilityGroup.all)
    end
  end

  context 'user can manage an organization' do
    let(:user_with_permission) do
      create(:user, permissions: [[:can_manage_an_organization, organization]])
    end

    it 'resolve all facility groups in their organization' do
      resolved_records = subject.new(user_with_permission, FacilityGroup.all).resolve
      expect(resolved_records).to match_array([facility_group_1, facility_group_2])
    end
  end

  context 'user can manage a facility group' do
    let(:user_with_permission) do
      create(:user, permissions: [[:can_manage_a_facility_group, facility_group_1]])
    end

    it 'resolve to their facility groups in their organization' do
      resolved_records = subject.new(user_with_permission, FacilityGroup.all).resolve
      expect(resolved_records).to match_array([facility_group_1])
    end
  end

  context 'other users' do
    let(:other_user) do
      create(:user, permissions: [])
    end

    it 'resolves an empty set' do
      resolved_records = subject.new(other_user, FacilityGroup.all).resolve
      expect(resolved_records).to be_empty
    end
  end
end
