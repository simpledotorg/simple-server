require 'rails_helper'

RSpec.describe AppointmentPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:supervisor) { create(:admin, :supervisor) }
  let(:analyst) { create(:admin, :analyst) }
  let(:organization_owner) { create(:admin, :organization_owner) }
  let(:counsellor) { create(:admin, :counsellor) }

  permissions :index?, :edit? do
    it 'permits owners' do
      expect(subject).to permit(owner, Appointment)
    end

    it 'permits counsellors' do
      expect(subject).to permit(counsellor, Appointment)
    end

    it 'permits supervisors' do
      expect(subject).to permit(supervisor, Appointment)
    end

    it 'denies organization_owners' do
      expect(subject).not_to permit(organization_owner, Appointment)
    end

    it 'denies analysts' do
      expect(subject).not_to permit(analyst, User)
    end
  end

  permissions :download? do
    it 'permits owners' do
      expect(subject).to permit(owner, Appointment)
    end

    context "supervisors" do
      let(:ihmi) { create(:organization, name: "IHMI") }
      let(:ihmi_group) { create(:facility_group, organization: ihmi) }
      let(:non_ihmi_group) { create(:facility_group) }

      before do
        ENV['IHCI_ORGANIZATION_UUID'] = ihmi.id
      end

      it 'permits supervisors in IHMI' do
        supervisor.admin_access_controls = [AdminAccessControl.new(access_controllable: ihmi_group)]
        expect(subject).to permit(supervisor, User)
      end

      it 'denies supervisors not in IHMI' do
        supervisor.admin_access_controls = [AdminAccessControl.new(access_controllable: non_ihmi_group)]
        expect(subject).not_to permit(supervisor, User)
      end
    end

    it 'denies counsellors' do
      expect(subject).not_to permit(counsellor, Appointment)
    end

    it 'denies organization_owners' do
      expect(subject).not_to permit(organization_owner, Appointment)
    end

    it 'denies analysts' do
      expect(subject).not_to permit(analyst, User)
    end
  end
end
