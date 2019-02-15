require 'rails_helper'

RSpec.describe AppointmentPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:supervisor) { create(:admin, :supervisor) }
  let(:analyst) { create(:admin, :analyst) }
  let(:organization_owner) { create(:admin, :organization_owner) }
  let(:counsellor) { create(:admin, :counsellor) }

  permissions :index?, :edit?, :cancel?, :update?, :cancel_with_reason? do
    it 'permits owners' do
      expect(subject).to permit(owner, Appointment)
    end

    it 'permits counsellors' do
      expect(subject).to permit(counsellor, Appointment)
    end

    it 'denies supervisors' do
      expect(subject).not_to permit(supervisor, User)
    end

    it 'denies organization_owner' do
      expect(subject).not_to permit(organization_owner, Appointment)
    end

    it 'denies analysts' do
      expect(subject).not_to permit(analyst, User)
    end
  end
end
