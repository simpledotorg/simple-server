require 'rails_helper'

RSpec.describe OverdueAppointmentPolicy do
  subject { described_class }

  let(:owner) { create(:admin, :owner) }
  let(:counsellor) { create(:admin, :counsellor) }

  permissions :index?, :edit?, :cancel?, :update? do
    it 'permits counsellors' do
      expect(subject).to permit(counsellor, OverdueAppointment)
    end

    it 'denies owners (and other admins)' do
      expect(subject).not_to permit(owner, OverdueAppointment)
    end
  end
end
