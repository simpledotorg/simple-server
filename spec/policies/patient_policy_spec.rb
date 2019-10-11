require 'rails_helper'

RSpec.describe PatientPolicy do
  subject { described_class }

  let(:facility1) { build(:facility) }
  let(:facility2) { build(:facility) }

  context 'user with permission to access patient information for all organizations' do
    let(:user_with_permission) do
      create(:admin, user_permissions: [build(:user_permission, permission_slug: :view_adherence_follow_up_list)])
    end

    permissions :index? do
      it 'permits the user' do
        expect(subject).to permit(user_with_permission, Patient)
      end
    end

    permissions :edit?, :update? do
      let(:patient1) { build(:patient, registration_facility: facility1) }
      let(:patient2) { build(:patient, registration_facility: facility2) }

      it 'permits the user to access all appointments' do
        expect(subject).to permit(user_with_permission, patient1)
        expect(subject).to permit(user_with_permission, patient2)
      end
    end
  end

  context 'user with permission to access patient information for an organization' do
    let(:user_with_permission) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :view_adherence_follow_up_list, resource: facility1.organization)
      ])
    end

    permissions :index? do
      it 'permits the user' do
        expect(subject).to permit(user_with_permission, Patient)
      end
    end

    permissions :edit?, :update? do
      let(:patient1) { build(:patient, registration_facility: facility1) }
      let(:patient2) { build(:patient, registration_facility: facility2) }

      it 'permits the user to access all patients in the give organization' do
        expect(subject).to permit(user_with_permission, patient1)
      end

      it 'denies the user to access any patient outside the give organization' do
        expect(subject).not_to permit(user_with_permission, patient2)
      end
    end
  end


  context 'user with permission to access patient information for a facility group' do
    let(:user_with_permission) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :view_adherence_follow_up_list, resource: facility1.facility_group)
      ])
    end

    permissions :index? do
      it 'permits the user' do
        expect(subject).to permit(user_with_permission, Patient)
      end
    end

    permissions :edit?, :update? do
      let(:patient1) { build(:patient, registration_facility: facility1) }
      let(:patient2) { build(:patient, registration_facility: facility2) }

      it 'permits the user to access all patients in the given facility_group' do
        expect(subject).to permit(user_with_permission, patient1)
      end

      it 'denies the user to access any patient outside the given facility_group' do
        expect(subject).not_to permit(user_with_permission, patient2)
      end
    end
  end

  context 'other users' do
    let(:user_without_necessary_permissions) do
      create(:admin, user_permissions: [])
    end

    permissions :index? do
      it 'denies the user' do
        expect(subject).not_to permit(user_without_necessary_permissions, Patient)
      end
    end

    permissions :edit?, :update? do
      let(:patient1) { build(:patient, registration_facility: facility1) }
      let(:patient2) { build(:patient, registration_facility: facility2) }

      it 'denies the user' do
        expect(subject).not_to permit(user_without_necessary_permissions, patient1)
        expect(subject).not_to permit(user_without_necessary_permissions, patient2)
      end
    end
  end
end

RSpec.describe PatientPolicy::Scope do
  let(:subject) { described_class }

  let(:organization) { create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }


  let(:facility1) { create(:facility, facility_group: facility_group) }
  let(:facility2) { create(:facility) }
  let!(:patient1) { create(:patient, registration_facility: facility1) }
  let!(:patient2) { create(:patient, registration_facility: facility2) }

  context 'user with permission to access patient information for all organizations' do
    let(:user) { create(:admin, user_permissions: [build(:user_permission, permission_slug: :view_adherence_follow_up_list)]) }

    it 'resolves all patients for users who can access patient information for all organizations' do
      resolved_records = subject.new(user, Patient.all).resolve
      expect(resolved_records).to match_array(Patient.all)
    end
  end

  context 'user with permission to access patient information for an organization' do
    let(:user) { create(:admin, user_permissions: [
      build(:user_permission, permission_slug: :view_adherence_follow_up_list, resource: organization)
    ]) }

    it 'resolves all patients in the organization' do
      resolved_records = subject.new(user, Patient.all).resolve
      expect(resolved_records).to match_array([patient1])
    end
  end

  context 'user with permission to access patient information for a facility group' do
    let(:user) { create(:admin, user_permissions: [
      build(:user_permission, permission_slug: :view_adherence_follow_up_list, resource: facility_group)
    ]) }

    it 'resolves all patients in the facility group' do
      resolved_records = subject.new(user, Patient.all).resolve
      expect(resolved_records).to match_array(Patient.where(registration_facility: facility_group.facilities))
    end
  end

  context 'other users' do
    let(:other_user) { create(:user) }

    it 'resolves no patients for other users' do
      resolved_records = subject.new(other_user, Patient.all).resolve
      expect(resolved_records).to match_array(Patient.none)
    end
  end
end
