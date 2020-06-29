require "rails_helper"
require "tasks/scripts/message_patients"

RSpec.describe MessagePatients do
  let(:message) { "Your health is important." }

  describe "#call" do
    context "sends a whatsapp message to all patients" do
      it "generates a status report" do
        patients = create_list(:patient, 2)

        mock_notification_service(patients.first)
        mock_notification_service(patients.second)

        expect(MessagePatients.call(Patient.all, message, verbose: false).report)
          .to eq({queued: [patients.first.id, patients.second.id]})
      end

      it "logs exceptions in the error report" do
        patients = create_list(:patient, 2)

        mock_notification_service(patients.first)
        mock_notification_service(patients.second, exception: true)

        expect(MessagePatients.call(Patient.all, message, verbose: false).report)
          .to eq({queued: [patients.first.id], exception: [patients.second.id]})
      end
    end

    context "sends an sms to all patients" do
      it "generates a status report" do
        patients = create_list(:patient, 2)

        mock_notification_service(patients.first)
        mock_notification_service(patients.second)

        expect(MessagePatients.call(Patient.all, message, channel: :sms, verbose: false).report)
          .to eq({queued: [patients.first.id, patients.second.id]})
      end

      it "logs exceptions in the error report" do
        patients = create_list(:patient, 2)

        mock_notification_service(patients.first)
        mock_notification_service(patients.second, exception: true)

        expect(MessagePatients.call(Patient.all, message, channel: :sms, verbose: false).report)
          .to eq({queued: [patients.first.id], exception: [patients.second.id]})
      end
    end

    it "only accepts patients as ActiveRecord::Relation" do
      patients = create_list(:patient, 2)

      expect {
        MessagePatients.call(patients, message, verbose: false)
      }.to raise_error(ArgumentError)
    end

    it "only accepts valid messaging channels" do
      _patients = create_list(:patient, 2)

      expect {
        MessagePatients.call(Patient.all, message, channel: :phone, verbose: false)
      }.to raise_error(ArgumentError)
    end
  end

  def mock_notification_service(patient, exception: false)
    notification_response = double("NotificationServiceResponse")

    if exception
      allow_any_instance_of(NotificationService)
        .to(receive(:send_whatsapp))
        .with(patient.latest_phone_number, message)
        .and_raise(Twilio::REST::TwilioError)

      allow_any_instance_of(NotificationService)
        .to(receive(:send_sms))
        .with(patient.latest_phone_number, message)
        .and_raise(Twilio::REST::TwilioError)
    else
      allow_any_instance_of(NotificationService)
        .to(receive(:send_whatsapp))
        .with(patient.latest_phone_number, message)
        .and_return(notification_response)

      allow_any_instance_of(NotificationService)
        .to(receive(:send_sms))
        .with(patient.latest_phone_number, message)
        .and_return(notification_response)

      expect(notification_response).to receive(:status).and_return("queued")
    end
  end
end
