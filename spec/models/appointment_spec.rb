require 'rails_helper'

describe Appointment, type: :model do
  describe 'Associations' do
    it { should belong_to(:patient) }
    it { should belong_to(:facility) }
    it { should have_many(:communications) }
  end

  describe 'Validations' do
    it_behaves_like 'a record that validates device timestamps'
  end

  describe 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end

  describe '.overdue' do
    let(:overdue_appointment) { create(:appointment, :overdue) }
    let(:upcoming_appointment) { create(:appointment) }

    it "includes overdue appointments" do
      expect(Appointment.overdue).to include(overdue_appointment)
    end

    it "excludes non-overdue appointments" do
      expect(Appointment.overdue).not_to include(upcoming_appointment)
    end
  end
end
