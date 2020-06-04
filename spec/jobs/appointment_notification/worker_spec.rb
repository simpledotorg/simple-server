require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe AppointmentNotification::Worker, type: :job do
  let!(:facility_name) { 'Simple Facility' }
  let!(:appointment_scheduled_date) { Date.new(2018, 1, 1) }
  let!(:appointment) do
    create(:appointment,
           facility: create(:facility, name: facility_name),
           scheduled_date: appointment_scheduled_date)
  end

  let(:appointment_phone_number) { appointment.patient.latest_mobile_number }
  let(:communication_type) { "missed_visit_sms_reminder" }
  let(:locale) { "en" }
  let(:expected_message) { "Our staff at Simple Facility are thinking of you and your heart health. Please continue your blood pressure medicines. Collect your medicine from the nearest sub centre. Contact your ANM or ASHA." }
  let(:callback_url) { "https://localhost/api/v3/twilio_sms_delivery" }

  before do
    notification_response = double('NotificationServiceResponse')
    allow_any_instance_of(NotificationService).to receive(:send_sms).and_return(notification_response)
    allow_any_instance_of(NotificationService).to receive(:send_whatsapp).and_return(notification_response)
    allow(notification_response).to receive(:sid).and_return(SecureRandom.uuid)
    allow(notification_response).to receive(:status).and_return('queued')
  end

  describe "#perform" do
    context "when communication_type is SMS" do
      it "sends a reminder SMS" do
        expect_any_instance_of(NotificationService).to receive(:send_sms).with(appointment_phone_number, expected_message, callback_url)

        described_class.perform_async(appointment.id, "missed_visit_sms_reminder", locale)
        described_class.drain
      end
    end

    context "when communication_type is WhatsApp" do
      it "sends a reminder WhatsApp" do
        expect_any_instance_of(NotificationService).to receive(:send_whatsapp).with(appointment_phone_number, expected_message, callback_url)

        described_class.perform_async(appointment.id, "missed_visit_whatsapp_reminder", locale)
        described_class.drain
      end
    end

    it "records a Communication log if successful" do
      expect {
        described_class.perform_async(appointment.id, communication_type, locale)
        described_class.drain
      }.to change { Communication.count }.by(1)
    end

    it "does not send if Communication already sent" do
      allow_any_instance_of(Appointment).to receive(:previously_communicated_via?).and_return(true)

      expect {
        described_class.perform_async(appointment.id, communication_type, locale)
        described_class.drain
      }.not_to change { Communication.count }
    end

    it "does not record a Communication log if any errors occur" do
      allow_any_instance_of(NotificationService).to receive(:send_sms).and_raise(Twilio::REST::TwilioError)
      allow_any_instance_of(NotificationService).to receive(:send_whatsapp).and_raise(Twilio::REST::TwilioError)

      expect {
        described_class.perform_async(appointment.id, communication_type, locale)
        described_class.drain
      }.not_to change { Communication.count }
    end

    describe "uses message translations" do
      context "when communication_type is SMS" do
        it "should have the message text in Marathi" do
          locale = "mr-IN"
          expected_message = 'आमचे Simple Facility येथील कर्मचारी तुमच्‍याबद्दल आणि तुमच्‍या ह्रदयाच्‍या आरोग्‍याबद्दल विचार करीत आहेत. कृपया आपल्या रक्तदाबाची औषधे चालू ठेवा. जवळच्या उपकेंद्रामधून आपले औषध घ्या. आपल्या ANM किंवा ASHA शी संपर्क साधा.'

          expect_any_instance_of(NotificationService).to receive(:send_sms).with(appointment_phone_number, expected_message, callback_url)

          described_class.perform_async(appointment.id, "missed_visit_sms_reminder", locale)
          described_class.drain
        end
      end

      context "when communication_type is WhatsApp" do
        it "should have the message text in Marathi" do
          locale = "mr-IN"
          expected_message = 'आमचे Simple Facility येथील कर्मचारी तुमच्‍याबद्दल आणि तुमच्‍या ह्रदयाच्‍या आरोग्‍याबद्दल विचार करीत आहेत. कृपया आपल्या रक्तदाबाची औषधे चालू ठेवा. जवळच्या उपकेंद्रामधून आपले औषध घ्या. आपल्या ANM किंवा ASHA शी संपर्क साधा.'

          expect_any_instance_of(NotificationService).to receive(:send_whatsapp).with(appointment_phone_number, expected_message, callback_url)

          described_class.perform_async(appointment.id, "missed_visit_whatsapp_reminder", locale)
          described_class.drain
        end
      end
    end

    it 'should raise an error if locale is invalid' do
      locale = "fr"

      expect do
        described_class.perform_async(appointment.id, communication_type, locale)
        described_class.drain
      end.to raise_error(I18n::InvalidLocale)
    end
  end
end
