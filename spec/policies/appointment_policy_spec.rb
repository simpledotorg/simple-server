require 'rails_helper'

RSpec.describe AppointmentPolicy do
  subject { described_class }

  let(:facility1) { build(:facility) }
  let(:facility2) { build(:facility) }

  context 'user with permission to access appointment information for all organizations' do
    let(:user_with_permission) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :can_access_appointment_information_for_all_organizations)
      ])
    end

    permissions :index? do
      it 'permits the user' do
        expect(subject).to permit(user_with_permission, Appointment)
      end
    end

    permissions :edit?, :update? do
      let(:appointment1) { build(:appointment, :overdue, facility: facility1) }
      let(:appointment2) { build(:appointment, :overdue, facility: facility2) }

      it 'permits the user to access all appointments' do
        expect(subject).to permit(user_with_permission, appointment1)
        expect(subject).to permit(user_with_permission, appointment2)
      end
    end
  end

  context 'user with permission to access appointment information for an organization' do
    let(:user_with_permission) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :can_access_appointment_information_for_organization, resource: facility1.organization)
      ])
    end

    permissions :index? do
      it 'permits the user' do
        expect(subject).to permit(user_with_permission, Appointment)
      end
    end

    permissions :edit?, :update? do
      let(:appointment1) { build(:appointment, :overdue, facility: facility1) }
      let(:appointment2) { build(:appointment, :overdue, facility: facility2) }

      it 'permits the user to access all appointments in the give organization' do
        expect(subject).to permit(user_with_permission, appointment1)
      end

      it 'denies the user to access any appointment outside the give organization' do
        expect(subject).not_to permit(user_with_permission, appointment2)
      end
    end
  end


  context 'user with permission to access appointment information for a facility group' do
    let(:user_with_permission) do
      create(:user, user_permissions: [
        build(:user_permission, permission_slug: :can_access_appointment_information_for_facility_group, resource: facility1.facility_group)])
    end

    permissions :index? do
      it 'permits the user' do
        expect(subject).to permit(user_with_permission, Appointment)
      end
    end

    permissions :edit?, :update? do
      let(:appointment1) { build(:appointment, :overdue, facility: facility1) }
      let(:appointment2) { build(:appointment, :overdue, facility: facility2) }

      before do
        ENV['IHCI_ORGANIZATION_UUID'] = ihmi.id
      end

      it 'permits supervisors in IHMI' do
        supervisor.admin_access_controls = [AdminAccessControl.new(access_controllable: ihmi_group)]
        expect(subject).to permit(supervisor, User)
      end

      it 'denies the user to access any appointment outside the given facility_group' do
        expect(subject).not_to permit(user_with_permission, appointment2)
      end
    end
  end

  context 'user with permission to access appointment information for a facility' do
    let(:user_with_permission) do
      create(:user, user_permissions: [
        build(:user_permission, permission_slug: :can_access_appointment_information_for_facility, resource: facility1)
      ])
    end

    permissions :index? do
      it 'permits the user' do
        expect(subject).to permit(user_with_permission, Appointment)
      end
    end

    permissions :edit?, :update? do
      let(:appointment1) { build(:appointment, :overdue, facility: facility1) }
      let(:appointment2) { build(:appointment, :overdue, facility: facility2) }

      it 'permits the user to access all appointments in the given facility' do
        expect(subject).to permit(user_with_permission, appointment1)
      end

      it 'denies the user to access any appointment outside the given facility' do
        expect(subject).not_to permit(user_with_permission, appointment2)
      end
    end
  end

  context 'other users' do
    let(:user_without_necessary_permissions) do
      create(:user)
    end

    permissions :index? do
      it 'denies the user' do
        expect(subject).not_to permit(user_without_necessary_permissions, Appointment)
      end
    end

    permissions :edit?, :update? do
      let(:appointment1) { build(:appointment, :overdue, facility: facility1) }
      let(:appointment2) { build(:appointment, :overdue, facility: facility2) }

      it 'denies the user' do
        expect(subject).not_to permit(user_without_necessary_permissions, appointment1)
        expect(subject).not_to permit(user_without_necessary_permissions, appointment2)
      end
    end
  end
end

RSpec.describe AppointmentPolicy::Scope do
  let(:subject) { described_class }

  let(:organization) { create(:organization) }
  let(:facility_group) { create(:facility_group, organization: organization) }


  let(:facility1) { create(:facility, facility_group: facility_group) }
  let(:facility2) { create(:facility) }
  let(:appointment1) { create(:appointment, :overdue, facility: facility1) }
  let(:appointment2) { create(:appointment, :overdue, facility: facility2) }

  context 'user with permission to access appointment information for all organizations' do
    let(:user) do
      create(:admin, user_permissions: [
        build(:user_permission, permission_slug: :can_access_appointment_information_for_all_organizations)
      ])
    end

    it 'resolves all appointments for users who can access appointment information for all organizations' do
      resolved_records = subject.new(user, Appointment.all).resolve
      expect(resolved_records).to match_array(Appointment.all)
    end
  end

  context 'user with permission to access appointment information for an organization' do
    let(:user) { create(:admin, user_permissions: [
      build(:user_permission, permission_slug: :can_access_appointment_information_for_organization, resource: organization)
    ]) }

    it 'resolves all appointments in the organization' do
      resolved_records = subject.new(user, Appointment.all).resolve
      expect(resolved_records).to match_array(Appointment.where(facility: organization.facilities))
    end
  end

  context 'user with permission to access appointment information for a facility group' do
    let(:user) { create(:admin, user_permissions: [
      build(:user_permission, permission_slug: :can_access_appointment_information_for_facility_group, resource: facility_group)
    ]) }

    it 'resolves all appointments in the facility group' do
      resolved_records = subject.new(user, Appointment.all).resolve
      expect(resolved_records).to match_array(Appointment.where(facility: facility_group.facilities))
    end
  end

  context 'user with permission to access appointment information for a facility group' do
    let(:user) { create(:admin, user_permissions: [
      build(:user_permission, permission_slug: :can_access_appointment_information_for_facility, resource: facility1)
    ]) }
    it 'resolves all appointments in the facility' do
      resolved_records = subject.new(user, Appointment.all).resolve
      expect(resolved_records).to match_array(Appointment.where(facility: facility1))
    end
  end

  context 'other users' do
    let(:other_user) { create(:user) }

    it 'resolves no appointments other users' do
      resolved_records = subject.new(other_user, Appointment.all).resolve
      expect(resolved_records).to match_array(Appointment.none)
    end
  end
end