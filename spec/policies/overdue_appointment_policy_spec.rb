require 'rails_helper'

RSpec.describe OverdueAppointmentPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:healthcare_counsellor) { create(:admin, :healthcare_counsellor) }

  permissions :index?, :edit?, :cancel?, :update? do
    it 'permits healthcare counsellors' do
      expect(subject).to permit(healthcare_counsellor, OverdueAppointment)
    end

    it 'denies owners (and other admins)' do
      expect(subject).not_to permit(owner, OverdueAppointment)
    end
  end
end

RSpec.describe OverdueAppointmentPolicy::Scope do
  let(:subject) { described_class }

  let(:overdue_appointment_1) { build(:overdue_appointment) }
  let(:patient_1) { overdue_appointment_1.patient }
  let(:facility_1) { patient_1.registration_facility }

  let(:facility_group) { facility_1.facility_group }

  let(:facility_2) { create(:facility, facility_group: facility_group) }
  let(:patient_2) { create(:patient, registration_facility: facility_2) }
  let!(:overdue_appointment_2) { build(:overdue_appointment, patient: patient_2) }

  describe 'owner' do
    let(:owner) { create(:admin, :owner) }
    it 'resolves no overdue appointments' do
      resolved_records = subject.new(owner, OverdueAppointment).resolve
      expect(resolved_records).to match_array([])
    end
  end

  describe 'healthcare counsellor' do
    let(:healthcare_counsellor) do
      create(:admin,
             :healthcare_counsellor,
             admin_access_controls: [AdminAccessControl.new(access_controllable: facility_group)])
    end

    it 'resolves all overdue appointments in their facility groups' do
      resolved_records = subject.new(healthcare_counsellor, OverdueAppointment).resolve
      expect(resolved_records).to contain_exactly(overdue_appointment_1, overdue_appointment_2)
    end
  end
end
