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