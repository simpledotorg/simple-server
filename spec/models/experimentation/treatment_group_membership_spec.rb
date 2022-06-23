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

      membership.record_notification("messages_report_key", notification)
      expect(membership.reload.messages["messages_report_key"]).to eq(
        {
          message_name: notification.message,
          remind_on: notification.remind_on.to_s,
          notification_status: notification.status,
          notification_status_updated_at: notification.updated_at.to_s,
          notification_id: notification.id,
          localized_message: notification.localized_message,
          created_at: notification.created_at.to_s
        }.with_indifferent_access
      )
    end

    it "should not overwrite older entries even if the membership record becomes stale" do
      notification = create(:notification)
      membership = create(:treatment_group_membership)

      membership.record_notification("messages_report_key_1", notification)
      notification_2 = create(:notification, message: "second notification")

      membership.record_notification("messages_report_key_2", notification_2)
      expect(membership.reload.messages["messages_report_key_1"]).to be_present
      expect(membership.reload.messages["messages_report_key_2"]).to be_present
    end
  end

  describe "#record_visit_details" do
    it "considers the earliest record out of BP, BS and drug for visit details" do
      membership = create(:treatment_group_membership, status: :enrolled, expected_return_date: 10.days.ago)
      patient = membership.patient

      bp = create(:blood_pressure, recorded_at: 6.days.ago, patient: patient)
      bs = create(:blood_sugar, recorded_at: 7.days.ago, patient: patient)
      drug = create(:prescription_drug, device_created_at: 8.days.ago, patient: patient)

      membership.record_visit(blood_pressure: bp, blood_sugar: bs, prescription_drug: drug)

      expect(membership.visit_blood_pressure_id).to eq(bp.id)
      expect(membership.visit_blood_sugar_id).to eq(bs.id)
      expect(membership.visit_prescription_drug_created).to eq(true)
      expect(membership.visited_at).to eq(drug.device_created_at)
      expect(membership.visit_facility_id).to eq(drug.facility_id)
      expect(membership.visit_facility_name).to eq(drug.facility.name)
      expect(membership.visit_facility_type).to eq(drug.facility.facility_type)
      expect(membership.visit_facility_block).to eq(drug.facility.block)
      expect(membership.visit_facility_district).to eq(drug.facility.district)
      expect(membership.visit_facility_state).to eq(drug.facility.state)
      expect(membership.status).to eq("visited")
      expect(membership.status_updated_at).to be_present
      expect(membership.status_reason).to eq("visit_recorded")
      expect(membership.days_to_visit).to eq(2)
    end
  end

  describe "#record_notification_results" do
    it "records results of a notification by message" do
      membership = create(:treatment_group_membership, messages: {"messages_report_key" => {}})
      delivery_result = {"delivery_result" => "This was delivered"}

      membership.record_notification_result("messages_report_key", delivery_result)

      expect(membership.messages["messages_report_key"]).to eq delivery_result
    end
  end
end
