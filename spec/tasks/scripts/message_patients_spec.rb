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

        report = MessagePatients.call(Patient.all, message, verbose: false).report

        expect(report[:queued]).to contain_exactly(patients.first.id, patients.second.id)
        expect(report[:exception]).to be_nil
      end

      it "logs exceptions in the error report" do
        patients = create_list(:patient, 2)

        mock_notification_service(patients.first)
        mock_notification_service(patients.second, exception: true)

        report = MessagePatients.call(Patient.all, message, verbose: false).report
        expect(report[:queued]).to contain_exactly(patients.first.id)
        expect(report[:exception]).to contain_exactly(patients.second.id)
      end
    end

    context "sends an sms to all patients" do
      it "generates a status report" do
        patients = create_list(:patient, 2)

        mock_notification_service(patients.first)
        mock_notification_service(patients.second)

        report = MessagePatients.call(Patient.all, message, channel: :sms, verbose: false).report
        expect(report[:queued]).to contain_exactly(patients.first.id, patients.second.id)
        expect(report[:exception]).to be_nil
      end

      it "logs exceptions in the error report" do
        patients = create_list(:patient, 2)

        mock_notification_service(patients.first)
        mock_notification_service(patients.second, exception: true)

        report = MessagePatients.call(Patient.all, message, channel: :sms, verbose: false).report
        expect(report[:queued]).to contain_exactly(patients.first.id)
        expect(report[:exception]).to contain_exactly(patients.second.id)
      end
    end

    describe "contactable patients" do
      it "only messages contactable patients by default" do
        patients = create_list(:patient, 2)

        patients.second.phone_numbers.each do |phone_number|
          phone_number.update!(phone_type: "landline")
        end

        mock_notification_service(patients.first)

        report = MessagePatients.call(Patient.all, message, channel: :sms, verbose: false).report
        expect(report[:queued]).to contain_exactly(patients.first.id)
        expect(report[:exception]).to be_nil
      end

      it "messages all patients if `only_contactable: false`" do
        patients = create_list(:patient, 2)

        patients.second.phone_numbers.each do |phone_number|
          phone_number.update!(phone_type: "landline")
        end

        mock_notification_service(patients.first)
        mock_notification_service(patients.second)

        report = MessagePatients.call(Patient.all, message, channel: :sms, only_contactable: false, verbose: false).report
        expect(report[:queued]).to contain_exactly(patients.first.id, patients.second.id)
        expect(report[:exception]).to be_nil
      end

      it "no-ops if a patient does not have a phone number" do
        patients = create_list(:patient, 2)

        patients.second.phone_numbers.each do |phone_number|
          phone_number.destroy!
        end

        mock_notification_service(patients.first)

        report = MessagePatients.call(Patient.all, message, channel: :sms, only_contactable: false, verbose: false).report
        expect(report[:queued]).to contain_exactly(patients.first.id)
        expect(report[:exception]).to be_nil
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
