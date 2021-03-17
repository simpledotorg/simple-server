require "rails_helper"

describe AppointmentReminder, type: :model do
  let(:patient) { create(:patient) }
  let(:appointment) { create(:appointment, patient: patient) }
  let(:appointment_reminder) { create(:appointment_reminder, patient: patient, appointment: appointment) }

  describe "associations" do
    it { should belong_to(:patient) }
    it { should belong_to(:experiment) }
    it { should belong_to(:appointment) }

    it { should have_many(:communications) }
  end

end