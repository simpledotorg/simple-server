require "rails_helper"

describe Notification, type: :model do
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

  describe "#message_data" do
    it "returns the variable content and subject's facility's locale" do
      notification = create(:notification)
      notification.patient.address.update!(state: "punjab")
      notification.subject = create(:appointment, patient: notification.patient)
      facility = notification.subject.facility
      facility.update!(state: "Maharashtra")

      expect(notification.message_data[:variable_content]).to eq({facility_name: notification.subject.facility.short_name,
                                                                   patient_name: notification.patient.full_name,
                                                                   appointment_date: notification.subject.scheduled_date.strftime("%d-%m-%Y")})
      expect(notification.message_data[:locale]).to eq(facility.locale)
    end

    context "when appointment is not present as the subject" do
      it "returns nil appointment_date" do
        notification = create(:notification, purpose: "experimental_appointment_reminder", subject: nil)
        expect(notification.message_data[:variable_content][:appointment_date]).to be_nil
      end

      it "returns the patient's assigned facility as the facility_name" do
        notification = create(:notification, purpose: "experimental_appointment_reminder", subject: nil)
        expect(notification.message_data[:variable_content][:facility_name]).to eq(notification.patient.assigned_facility.short_name)
      end

      it "returns the patient's assigned facility's locale" do
        notification = create(:notification, purpose: "experimental_appointment_reminder", subject: nil)
        expect(notification.message_data[:locale]).to eq(notification.patient.assigned_facility.locale)
      end
    end
  end

  describe "#localized_message" do
    it "localizes the message according to the facility state, not the patient's address" do
      notification = create(:notification)
      notification.patient.address.update!(state: "punjab")
      notification.subject = create(:appointment, patient: notification.patient)
      facility = notification.subject.facility
      facility.update!(state: "Maharashtra")

      expected_message = I18n.t(
        notification.message,
        facility_name: notification.subject.facility.short_name,
        patient_name: notification.patient.full_name,
        appointment_date: notification.subject.scheduled_date.strftime("%d-%m-%Y"),
        locale: "mr-IN"
      )
      expect(notification.localized_message).to eq(expected_message)
    end

    context "when appointment is not present as the subject" do
      it "does not throw an error and localizes a message that requires an appointment_date with a blank date" do
        allow_any_instance_of(Facility).to receive(:locale).and_return("en")
        notification = create(:notification, purpose: "experimental_appointment_reminder", subject: nil)
        patient = notification.patient
        notification.update(
          subject: nil,
          message: "notifications.set01.basic"
        )

        expected_message = "#{patient.full_name}, please visit #{patient.assigned_facility.short_name} on  for a BP measure and medicines."
        expect(notification.localized_message).to eq(expected_message)
      end
    end
  end

  describe "#dlt_template_name" do
    it "returns the dlt_template_name using the locale and the message" do
      allow_any_instance_of(Facility).to receive(:locale).and_return("en")
      notification = create(:notification, message: "notifications.set01.basic")
      allow(Messaging::Bsnl::DltTemplate).to receive(:latest_name_of).and_return("en.notifications.set01.basic.200")

      expect(notification.dlt_template_name).to eq("en.notifications.set01.basic.200")
    end
  end

  describe "#delivery_result" do
    it "is failed if no successful deliveries are present" do
      notification = create(:notification)

      unsuccessful_communication = create(:communication, notification: notification)
      create(:twilio_sms_delivery_detail, :failed, communication: unsuccessful_communication)
      notification.update(status: :sent)

      expect(notification.delivery_result).to eq(:failed)
    end

    it "is failed if notification is cancelled even if successful communications are present" do
      notification = create(:notification, status: :cancelled)
      successful_communication = create(:communication, notification: notification)
      create(:twilio_sms_delivery_detail, :sent, communication: successful_communication)

      expect(notification.delivery_result).to eq(:failed)
    end

    it "is success if at least one successful deliveries are present" do
      notification = create(:notification)

      unsuccessful_communication = create(:communication, notification: notification)
      create(:twilio_sms_delivery_detail, :failed, communication: unsuccessful_communication)
      notification.update(status: :sent)

      successful_communication = create(:communication, notification: notification)
      create(:twilio_sms_delivery_detail, :sent, communication: successful_communication)

      expect(notification.delivery_result).to eq(:success)
    end

    it "is queued if no deliveries are present" do
      notification = create(:notification)
      expect(notification.delivery_result).to eq(:queued)
    end

    it "is queued if at least one queued deliveries are present" do
      notification = create(:notification)

      unsuccessful_communication = create(:communication, notification: notification)
      create(:twilio_sms_delivery_detail, :failed, communication: unsuccessful_communication)
      notification.update(status: :sent)

      queued_communication = create(:communication, notification: notification)
      create(:twilio_sms_delivery_detail, :queued, communication: queued_communication)

      expect(notification.delivery_result).to eq(:queued)
    end
  end

  describe "#record_communication" do
    it "ties the communication to a notification and updates status to 'sent'" do
      notification = create(:notification)
      communication = create(:communication)
      notification.record_communication(communication)

      expect(communication.reload.notification_id).to eq(notification.id)
      expect(notification.reload.status).to eq("sent")
    end
  end
end
