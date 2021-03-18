require "rails_helper"

describe AppointmentReminder, type: :model do

  describe "associations" do

    it { should belong_to(:appointment) }

    it "should set experiment id when provided" do
      allow(ActiveYaml::Base).to receive(:actual_root_path).and_return(Rails.root + "spec/fixtures")
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
