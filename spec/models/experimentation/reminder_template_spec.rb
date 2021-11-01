require "rails_helper"

RSpec.describe Experimentation::ReminderTemplate, type: :model do
  describe "associations" do
    it { should belong_to(:treatment_group) }
    it { should have_many(:notifications) }
  end

  describe "validations" do
    it { should validate_presence_of(:message) }
    it { should validate_presence_of(:remind_on_in_days) }
    it { should validate_numericality_of(:remind_on_in_days) }

    it "allows only one template with a message in a group" do
      treatment_group = create(:treatment_group)
      message = "Hello please visit the clinic."
      create(:reminder_template, treatment_group: treatment_group, message: message)

      new_reminder_template = build(:reminder_template, treatment_group: treatment_group, message: message)
      new_reminder_template.validate

      expect(new_reminder_template.errors[:message]).to be_present
    end

    it "allows same message in another group" do
      treatment_group = create(:treatment_group, experiment: create(:experiment, experiment_type: "current_patients"))
      other_treatment_group = create(:treatment_group, experiment: create(:experiment, experiment_type: "stale_patients"))
      message = "Hello please visit the clinic."
      create(:reminder_template, treatment_group: treatment_group, message: message)

      other_group_reminder_template = build(:reminder_template, treatment_group: other_treatment_group, message: message)
      other_group_reminder_template.validate

      expect(other_group_reminder_template.errors[:message]).not_to be_present
    end
  end
end
