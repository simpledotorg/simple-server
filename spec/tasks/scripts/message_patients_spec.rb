# frozen_string_literal: true

require "rails_helper"
require "tasks/scripts/message_patients"

RSpec.describe MessagePatients do
  let(:message) { "Your health is important." }
  let(:patients) { create_list(:patient, 2) }
  let(:patient) { create(:patient) }

  describe "#call" do
    context "sends a whatsapp message to all patients" do
      it "generates a status report" do
        patient
        mock_successful_delivery

        report = MessagePatients.call(Patient.all, message, verbose: false).report

        expect(report[:queued]).to contain_exactly(patient.id)
        expect(report[:exception]).to be_nil
      end

      it "logs exceptions in the error report" do
        patient

        report = MessagePatients.call(Patient.all, message, verbose: false).report
        expect(report[:queued]).to be_nil
        expect(report[:exception]).to contain_exactly(patient.id)
      end
    end

    context "sends an sms to all patients" do
      it "generates a status report" do
        patient
        mock_successful_delivery

        report = MessagePatients.call(Patient.all, message, channel: :sms, verbose: false).report
        expect(report[:queued]).to contain_exactly(patient.id)
        expect(report[:exception]).to be_nil
      end

      it "logs exceptions in the error report" do
        patient

        report = MessagePatients.call(Patient.all, message, channel: :sms, verbose: false).report
        expect(report[:queued]).to be_nil
        expect(report[:exception]).to contain_exactly(patient.id)
      end
    end

    describe "contactable patients" do
      it "only messages contactable patients by default" do
        patients.second.phone_numbers.each do |phone_number|
          phone_number.update!(phone_type: "landline")
        end

        mock_successful_delivery

        report = MessagePatients.call(Patient.all, message, channel: :sms, verbose: false).report
        expect(report[:queued]).to contain_exactly(patients.first.id)
        expect(report[:exception]).to be_nil
      end

      it "messages all patients if `only_contactable: false`" do
        patients.second.phone_numbers.each do |phone_number|
          phone_number.update!(phone_type: "landline")
        end

        mock_successful_delivery

        report = MessagePatients.call(Patient.all, message, channel: :sms, only_contactable: false, verbose: false).report
        expect(report[:queued]).to contain_exactly(patients.first.id, patients.second.id)
        expect(report[:exception]).to be_nil
      end

      it "no-ops if a patient does not have a phone number" do
        patients.second.phone_numbers.each do |phone_number|
          phone_number.destroy!
        end

        mock_successful_delivery

        report = MessagePatients.call(Patient.all, message, channel: :sms, only_contactable: false, verbose: false).report
        expect(report[:queued]).to contain_exactly(patients.first.id)
        expect(report[:exception]).to be_nil
      end
    end

    it "only accepts patients as ActiveRecord::Relation" do
      expect {
        MessagePatients.call(patients, message, verbose: false)
      }.to raise_error(ArgumentError)
    end

    it "only accepts valid messaging channels" do
      expect {
        MessagePatients.call(Patient.all, message, channel: :phone, verbose: false)
      }.to raise_error(ArgumentError)
    end
  end

  def mock_successful_delivery
    response_double = double("NotificationServiceResponse")
    twilio_client = double

    allow(response_double).to receive(:status).and_return("queued")
    allow_any_instance_of(TwilioApiService).to receive(:client).and_return(twilio_client)
    allow(twilio_client).to receive_message_chain("messages.create").and_return(response_double)
  end
end
