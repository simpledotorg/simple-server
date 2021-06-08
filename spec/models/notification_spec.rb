require "rails_helper"

describe Notification, type: :model do
  let(:notification) { create(:notification) }

  describe "associations" do
    it { should belong_to(:subject).optional }
    it { should belong_to(:patient) }
    it { should belong_to(:experiment).optional }
    it { should belong_to(:reminder_template).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:remind_on) }
    it { should validate_presence_of(:message) }
  end

  describe "#localized_message" do
    it "localizes the message according to the facility state, not the patient's address" do
      notification.patient.address.update!(state: "punjab")
      notification.subject = create(:appointment, patient: notification.patient)
      facility = notification.subject.facility
      facility.update(state: "Maharashtra")

      expected_message = I18n.t(
        notification.message,
        facility_name: notification.subject.facility.name,
        patient_name: notification.patient.full_name,
        appointment_date: notification.subject.scheduled_date,
        locale: "mr-IN"
      )
      expect(notification.localized_message).to eq(expected_message)
    end
  end

  describe "#next_communication_type" do
    context "when WhatsApp flag is on" do
      before { Flipper.enable(:whatsapp_appointment_reminders) }

      it "returns missed_visit_whatsapp_reminder if it has no whatsapp communications" do
        expect(notification.next_communication_type).to eq("missed_visit_whatsapp_reminder")
      end

      it "returns missed_visit_sms_reminder if it has a whatsapp communication but no sms communication" do
        create(:communication, communication_type: "missed_visit_whatsapp_reminder", notification: notification)
        expect(notification.next_communication_type).to eq("missed_visit_sms_reminder")
      end

      it "returns nil if it has both a whatsapp and sms communication" do
        create(:communication, communication_type: "missed_visit_whatsapp_reminder", notification: notification)
        create(:communication, communication_type: "missed_visit_sms_reminder", notification: notification)
        expect(notification.next_communication_type).to eq(nil)
      end
    end

    context "when WhatsApp flag is off" do
      it "returns missed_visit_sms_reminder if it has no sms communication" do
        expect(notification.next_communication_type).to eq("missed_visit_sms_reminder")
      end

      it "returns nil if it has an sms communication" do
        create(:communication, communication_type: "missed_visit_sms_reminder", notification: notification)
        expect(notification.next_communication_type).to eq(nil)
      end
    end

    it "returns nil when notification is cancelled" do
      notification.status_cancelled!
      expect(notification.next_communication_type).to eq(nil)
    end

    it "returns nil when it belongs to a cancelled experiment" do
      experimental_notification = create(:notification, :with_experiment)
      experimental_notification.experiment.cancelled_state!
      expect(experimental_notification.next_communication_type).to eq(nil)
    end
  end
end
