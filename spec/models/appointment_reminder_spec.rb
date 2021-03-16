require "rails_helper"

describe AppointmentReminder, type: :model do
  subject(:appointment_reminder) { create(:appointment_reminder) }

  describe "associations" do
    it { should belong_to(:patient) }
    it { should belong_to(:experiment) }
    it { should belong_to(:appointment) }

    it { should have_many(:communications) }
  end

end