# frozen_string_literal: true

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
    it { should validate_presence_of(:purpose) }

    it "requires a subject for missed visit reminders" do
      notification = build(:notification, purpose: :missed_visit_reminder, subject: nil)
      expect(notification.valid?).to be_falsey
      expect(notification.errors[:subject]).to eq(["can't be blank"])
    end

    it "does not require a subject for experiment reminders" do
      notification = build(:notification, purpose: :experimental_appointment_reminder, subject: nil)
      expect(notification.valid?).to be_truthy
    end
  end

  describe "#localized_message" do
    it "localizes the message according to the facility state, not the patient's address" do
      notification.patient.address.update!(state: "punjab")
      notification.subject = create(:appointment, patient: notification.patient)
      facility = notification.subject.facility
      facility.update!(state: "Maharashtra")

      expected_message = I18n.t(
        notification.message,
        facility_name: notification.subject.facility.name,
        patient_name: notification.patient.full_name,
        appointment_date: notification.subject.scheduled_date.strftime("%d-%m-%Y"),
        locale: "mr-IN"
      )
      expect(notification.localized_message).to eq(expected_message)
    end

    it "provides translation values based on purpose" do
      covid_medication_reminder = create(:notification, message: "notifications.covid.medication_reminder",
                                                        subject: nil,
                                                        purpose: "covid_medication_reminder")
      expect { covid_medication_reminder.localized_message }.not_to raise_error

      appointment = create(:appointment)
      missed_visit_reminder = create(:notification, message: "#{Notification::APPOINTMENT_REMINDER_MSG_PREFIX}.whatsapp",
                                                    purpose: :missed_visit_reminder,
                                                    subject: appointment)
      expect(missed_visit_reminder.localized_message).to include(appointment.facility.name)
    end
  end

  describe "#next_communication_type" do
    context "when WhatsApp flag is on" do
      before { Flipper.enable(:whatsapp_appointment_reminders) }

      it "returns whatsapp if it has no whatsapp communications" do
        expect(notification.next_communication_type).to eq("whatsapp")
      end

      it "returns sms if it has a whatsapp communication but no sms communication" do
        create(:communication, communication_type: "whatsapp", notification: notification)
        expect(notification.next_communication_type).to eq("sms")
      end

      it "returns nil if it has both a whatsapp and sms communication" do
        create(:communication, communication_type: "whatsapp", notification: notification)
        create(:communication, communication_type: "sms", notification: notification)
        expect(notification.next_communication_type).to eq(nil)
      end
    end

    context "when WhatsApp flag is off" do
      it "returns sms if it has no sms communication" do
        expect(notification.next_communication_type).to eq("sms")
      end

      it "returns nil if it has an sms communication" do
        create(:communication, communication_type: "sms", notification: notification)
        expect(notification.next_communication_type).to eq(nil)
      end
    end

    it "returns nil when notification is cancelled" do
      notification.status_cancelled!
      expect(notification.next_communication_type).to eq(nil)
    end
  end

  describe "#delivery_result" do
    it "is failed if no successful deliveries are present" do
      notification = create(:notification)

      unsuccessful_communication = create(:communication, notification: notification, user: nil, appointment: nil)
      create(:twilio_sms_delivery_detail, :failed, communication: unsuccessful_communication)
      notification.update(status: :sent)

      expect(notification.delivery_result).to eq(:failed)
    end

    it "is failed if notification is cancelled even if successful communications are present" do
      notification = create(:notification, status: :cancelled)
      successful_communication = create(:communication, notification: notification, user: nil, appointment: nil)
      create(:twilio_sms_delivery_detail, :sent, communication: successful_communication)

      expect(notification.delivery_result).to eq(:failed)
    end

    it "is success if at least one successful deliveries are present" do
      notification = create(:notification)

      unsuccessful_communication = create(:communication, notification: notification, user: nil, appointment: nil)
      create(:twilio_sms_delivery_detail, :failed, communication: unsuccessful_communication)
      notification.update(status: :sent)

      successful_communication = create(:communication, notification: notification, user: nil, appointment: nil)
      create(:twilio_sms_delivery_detail, :sent, communication: successful_communication)

      expect(notification.delivery_result).to eq(:success)
    end

    it "is queued if no deliveries are present" do
      notification = create(:notification)
      expect(notification.delivery_result).to eq(:queued)
    end

    it "is queued if at least one queued deliveries are present" do
      notification = create(:notification)

      unsuccessful_communication = create(:communication, notification: notification, user: nil, appointment: nil)
      create(:twilio_sms_delivery_detail, :failed, communication: unsuccessful_communication)
      notification.update(status: :sent)

      queued_communication = create(:communication, notification: notification, user: nil, appointment: nil)
      create(:twilio_sms_delivery_detail, :queued, communication: queued_communication)

      expect(notification.delivery_result).to eq(:queued)
    end
  end
end
