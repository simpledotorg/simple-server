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

  describe '.overdue_appointments_report' do
    let(:facility) { create(:facility) }

    it "should group overdue appointments by facility" do
      overdue_appointment = create(:appointment, :overdue, facility: facility)

      expected = {}
      expected[facility] = [overdue_appointment]
      expect(Appointment.overdue_appointments_report).to eq(expected)
    end

    it "should exclude overdue appointments that don't have patients" do
      overdue_appointment = create(:appointment, :overdue, facility: facility)
      create(:appointment, facility: facility)

      expected = {}
      expected[facility] = [overdue_appointment]
      expect(Appointment.overdue_appointments_report).to eq(expected)
    end

    it "should be empty if there are no overdue appointments" do
      expect(Appointment.overdue_appointments_report).to eq({})
    end
  end
end
