require 'rails_helper'

RSpec.describe PatientPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:supervisor) { create(:admin, :supervisor) }
  let(:analyst) { create(:admin, :analyst) }
  let(:organization_owner) { create(:admin, :organization_owner) }
  let(:counsellor) { create(:admin, :counsellor) }

  permissions :index?, :edit?, :cancel?, :update? do
    it 'permits owners' do
      expect(subject).to permit(owner, Patient)
    end

    it 'permits counsellors' do
      expect(subject).to permit(counsellor, Patient)
    end

    it 'denies supervisors' do
      expect(subject).not_to permit(supervisor, Patient)
    end

    it 'denies organization_owner' do
      expect(subject).not_to permit(organization_owner, Patient)
    end

    it 'denies analysts' do
      expect(subject).not_to permit(analyst, Patient)
    end
  end
end
