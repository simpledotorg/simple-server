require "rails_helper"

RSpec.describe Experimentation::TreatmentGroupMembership, type: :model do
  describe "associations" do
    it { should belong_to(:treatment_group) }
    it { should belong_to(:patient) }
    it { should belong_to(:experiment) }
  end

  describe "validations" do
    it "should validate that a patient is allowed only in only one active experiment at a time" do
      experiment_1 = create(:experiment, :running, experiment_type: "current_patients")
      experiment_2 = create(:experiment, :running, experiment_type: "stale_patients")

      treatment_group_1 = create(:treatment_group, experiment: experiment_1)
      treatment_group_2 = create(:treatment_group, experiment: experiment_2)

      patient = create(:patient, age: 18)

      treatment_group_1.enroll(patient)
      treatment_group_2_membership = build(:treatment_group_membership, patient: patient, treatment_group: treatment_group_2)

      treatment_group_2_membership.validate
      expect(treatment_group_2_membership.errors).to be_present
    end
  end

  describe "#record_notification" do
    it "should create a new entry if no messages exist" do
      notification = create(:notification)
      membership = create(:treatment_group_membership)

      membership.record_notification(notification)
      expect(membership.reload.messages[notification.message]).to eq(
        {
          remind_on: notification.remind_on.to_s,
          status: notification.status,
          notification_id: notification.id,
          localized_message: notification.localized_message,
          created_at: notification.created_at.to_s
        }.with_indifferent_access
      )
    end

    it "should not overwrite older entries even if the membership record becomes stale" do
      notification = create(:notification)
      membership = create(:treatment_group_membership)

      membership.record_notification(notification)
      notification_2 = create(:notification, message: "second notification")

      membership.record_notification(notification_2)
      expect(membership.reload.messages[notification.message]).to be_present
      expect(membership.reload.messages[notification_2.message]).to be_present
    end
  end

  describe "#record_notification_results" do
    it "records results of a notification by message" do
      membership = create(:treatment_group_membership, messages: {"message" => {}})
      delivery_result = {"delivery_result" => "This was delivered"}

      membership.record_notification_result("message", delivery_result)

      expect(membership.messages["message"]).to eq delivery_result
    end
  end
end
