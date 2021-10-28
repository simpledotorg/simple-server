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

    describe "#unique_message_per_group" do
      it "allows only one template with a message in a group" do
        treatment_group = create(:treatment_group)
        message = "Hello please visit the clinic."
        create(:reminder_template, treatment_group: treatment_group, message: message)

        new_reminder_template = build(:reminder_template, treatment_group: treatment_group, message: message)
        new_reminder_template.validate

        expect(new_reminder_template.errors[:message]).to be_present
      end
    end
  end
end
