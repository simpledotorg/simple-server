require 'rails_helper'

RSpec.describe AppointmentPolicy do
  subject { described_class }

  let(:facility1) { create(:facility) }
  let(:facility2) { create(:facility) }

  let(:user_can_manage_all_organizations) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_manage_all_organizations, resource: nil)
    user
  end

  let(:user_can_manage_overdue_list_for_facility1) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_manage_overdue_list_for_facility, resource: facility1)
    user
  end

  let(:other_user) { create(:master_user) }

  permissions :index? do
    it 'permits users who can manage overdue list for a facility' do
      expect(subject).to permit(user_can_manage_overdue_list_for_facility1, facility1)
    end

    it 'permits users who can manage all organizations' do
      expect(subject).to permit(user_can_manage_all_organizations, facility1)
      expect(subject).to permit(user_can_manage_all_organizations, facility2)
    end

    it 'denies other users from managing overdue list for a facility' do
      expect(subject).not_to permit(other_user, facility1)
      expect(subject).not_to permit(other_user, facility2)
    end
  end

  permissions :edit? do
    let(:appointment1) { create(:appointment, :overdue, facility: facility1) }
    let(:appointment2) { create(:appointment, :overdue, facility: facility2) }

    it 'permits users who can manage overdue list for a facility' do
      expect(subject).to permit(user_can_manage_overdue_list_for_facility1, appointment1)
    end

    it 'permits users who can manage all organizations' do
      expect(subject).to permit(user_can_manage_all_organizations, appointment1)
      expect(subject).to permit(user_can_manage_all_organizations, appointment2)
    end

    it 'denies other users from managing overdue list for a facility' do
      expect(subject).not_to permit(other_user, appointment1)
    end

    it 'denies uses from managing overdue list for a different facility' do
      expect(subject).not_to permit(user_can_manage_overdue_list_for_facility1, appointment2)
    end
  end

  permissions :download? do
    let(:user_can_download_overdue_list_for_facility1) do
      user = create(:master_user)
      create(:user_permission, user: user, permission_slug: :can_download_overdue_list_for_facility, resource: facility1)
      user
    end

    it 'permits users who manage all organizations' do
      expect(subject).to permit(user_can_manage_all_organizations, facility1)
      expect(subject).to permit(user_can_manage_all_organizations, facility2)
    end

    it 'permits users who can manage overdue list for a facility' do
      expect(subject).to permit(user_can_download_overdue_list_for_facility1, facility1)
    end

    it 'denies other users from managing overdue list for a facility' do
      expect(subject).not_to permit(other_user, facility1)
      expect(subject).not_to permit(other_user, facility2)
    end

    it 'denies uses from managing overdue list for a different facility' do
      expect(subject).not_to permit(user_can_download_overdue_list_for_facility1, facility2)
    end
  end
end

RSpec.describe AppointmentPolicy::Scope do
  let(:subject) { described_class }

  let(:facility1) { create(:facility) }
  let(:facility2) { create(:facility) }

  let(:appointment1) { create(:appointment, :overdue, facility: facility1) }
  let(:appointment2) { create(:appointment, :overdue, facility: facility2) }

  let(:user_can_manage_all_organizations) do
    user = create(:master_user)
    create(:user_permission,
           user: user,
           permission_slug: :can_manage_all_organizations)
    user
  end

  let(:user_can_manage_overdue_list_for_facility1) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_manage_overdue_list_for_facility, resource: facility1)
    user
  end

  let(:user_can_download_overdue_list_for_facility1) do
    user = create(:master_user)
    create(:user_permission, user: user, permission_slug: :can_download_overdue_list_for_facility, resource: facility2)
    user
  end

  let(:other_user) { create(:master_user) }

  context 'user who can manager all organisations' do
    it 'resolves all appointments' do
      resolved_records = subject.new(user_can_manage_all_organizations, Appointment.all).resolve
      expect(resolved_records).to match_array(Appointment.all.to_a)
    end
  end

  context 'user who can manage overdue list for a facility' do
    it 'resolves all appointments for facilities for which the user is authorised' do
      resolved_records = subject.new(user_can_manage_overdue_list_for_facility1, Appointment.all).resolve
      expect(resolved_records).to match_array([appointment1])
    end
  end

  context 'user who can download overdue list for a facility' do
    it 'resolves all appointments for facilities for which the user is authorised' do
      resolved_records = subject.new(user_can_download_overdue_list_for_facility1, Appointment.all).resolve
      expect(resolved_records).to match_array([appointment2])
    end
  end

  context 'other users' do
    it 'resolves no appointments' do
      resolved_records = subject.new(other_user, Appointment.all).resolve
      expect(resolved_records).to be_empty
    end
  end
end