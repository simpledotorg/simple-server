require 'rails_helper'

RSpec.describe AdherenceFollowUp::FacilityPolicy do
  subject { described_class }

  let(:facility) { build(:facility) }

  context 'user with permission to download appointment information for all organizations' do
    let(:user_with_permission) do
      create(:admin, user_permissions: [
               build(:user_permission, permission_slug: :download_adherence_follow_up_list)
             ])
    end

    permissions :download? do
      it 'permits the user' do
        expect(subject).to permit(user_with_permission, facility)
      end
    end
  end

  context 'user with permission to download appointment information for an organization' do
    let(:user_with_permission) do
      create(:admin, user_permissions: [
               build(:user_permission, permission_slug: :download_adherence_follow_up_list, resource: facility.organization)
             ])
    end

    permissions :download? do
      it 'permits the user' do
        expect(subject).to permit(user_with_permission, facility)
      end
    end
  end

  context 'user with permission to download appointment information for a facility group' do
    let(:user_with_permission) do
      create(:user, user_permissions: [
               build(:user_permission, permission_slug: :download_adherence_follow_up_list, resource: facility.facility_group)
             ])
    end

    permissions :download? do
      it 'permits the user' do
        expect(subject).to permit(user_with_permission, facility)
      end
    end
  end

  context 'other users' do
    let(:user_without_necessary_permissions) do
      create(:user)
    end

    permissions :download? do
      it 'denies the user' do
        expect(subject).not_to permit(user_without_necessary_permissions, facility)
      end
    end
  end
end
