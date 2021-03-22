require "rails_helper"

describe AppointmentReminder, type: :model do
  describe "associations" do
    it { should belong_to(:appointment) }

    # can't use the belong_to test here because it would require Experiment to have many
    # AppointmentReminders. has_many can be made to work for ActiveYaml by including an additional
    # module but i don't expect us to need Experiment.appointment_reminders functionality
    it "should set experiment id when provided" do
      appointment = create(:appointment)
      experiment = Experiment.first
      reminder = create(:appointment_reminder, appointment: appointment, experiment_id: experiment.id)
      expect(reminder.experiment_id).to eq(experiment.id)
    end
  end

  describe "validations" do
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:remind_on) }
  end
end
