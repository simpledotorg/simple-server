require 'rails_helper'

RSpec.describe SmsNotificationService do
  let!(:facility_name) { 'Simple Facility' }
  let!(:appointment_scheduled_date) { Date.new(2018, 1, 1) }
  let!(:appointment) do
    create(:appointment,
           facility: create(:facility, name: facility_name),
           scheduled_date: appointment_scheduled_date)
  end

  let(:twilio_client) { double('TwilioClientDouble') }
  let(:sender_phone_number) { ENV['TWILIO_PHONE_NUMBER'] }
  let(:recipient_phone_number) { '8585858585' }
  let(:expected_sms_recipient_phone_number) { '+918585858585' }

  subject(:sms) { SmsNotificationService.new(recipient_phone_number, sender_phone_number, twilio_client) }

  describe '#send_patient_request_otp_sms' do
    it 'does stuff' do
      expect(twilio_client).to receive_message_chain('messages.create').with(
        from: '+15005550006',
        to: expected_sms_recipient_phone_number,
        status_callback: '',
        body: /123456/
      )

      sms.send_patient_request_otp_sms('123456')
    end

  end

  describe '#send_reminder_sms' do
    context 'follow_up_reminder' do
      it 'should have the SMS body in the default locale' do
        sms = SmsNotificationService.new(recipient_phone_number, sender_phone_number, twilio_client)

        expected_msg_default = 'Our staff at Simple Facility are thinking of you and your heart health. Our health team is always here if you have any follow-up questions or concerns.'
        expect(twilio_client).to receive_message_chain('messages.create').with(from: '+15005550006',
                                                                               to: expected_sms_recipient_phone_number,
                                                                               status_callback: '',
                                                                               body: expected_msg_default)

        sms.send_reminder_sms('missed_visit_sms_reminder', appointment, '')
      end

      it 'should have the SMS body in Marathi' do
        sms = SmsNotificationService.new(recipient_phone_number, sender_phone_number, twilio_client)

        expected_msg_marathi = 'आमचे Simple Facility चे कर्मचारी तुमचा आणि तुमच्या हृदयाच्या आरोग्याचा विचार करत आहेत. तुमच्या प्रश्नांची किंवा समस्यांची उत्तरे देण्यास आमची हेल्थ टीम सदैव तत्पर आहे.'
        expect(twilio_client).to receive_message_chain('messages.create').with(from: '+15005550006',
                                                                               to: expected_sms_recipient_phone_number,
                                                                               status_callback: '',
                                                                               body: expected_msg_marathi)

        sms.send_reminder_sms('missed_visit_sms_reminder', appointment, '', 'mr-IN')
      end

      it 'should have the SMS body in Punjabi' do
        sms = SmsNotificationService.new(recipient_phone_number, sender_phone_number, twilio_client)

        expected_msg_punjabi = 'Simple Facility ਵਿੱਚ ਸਾਡੇ ਕਰਮਚਾਰੀ ਤੁਹਾਡੇ ਅਤੇ ਤੁਹਾਡੇ ਦਿਲ ਦੀ ਸਿਹਤ ਬਾਰੇ ਸੋਚ ਰਹੇ ਹਨ । ਜੇ ਤੁਹਾਡੇ ਮਨ ਵਿੱਚ ਕੋਈ ਪ੍ਰਸ਼ਨ ਜਾਂ ਚਿੰਤਾ ਹੈ ਤਾਂ ਸਾਡੀ ਸਿਹਤ ਟੀਮ ਹਮੇਸ਼ਾ ਤੁਹਾਡੇ ਲਈ ਇੱਥੇ ਹੈ ।'
        expect(twilio_client).to receive_message_chain('messages.create').with(from: '+15005550006',
                                                                               to: expected_sms_recipient_phone_number,
                                                                               status_callback: '',
                                                                               body: expected_msg_punjabi)

        sms.send_reminder_sms('missed_visit_sms_reminder', appointment, '', 'pa-Guru-IN')
      end

      it 'should raise an error if the locale for the SMS body is unsupported' do
        sms = SmsNotificationService.new(recipient_phone_number, sender_phone_number, twilio_client)

        expect do
          sms.send_reminder_sms('missed_visit_sms_reminder', appointment, ' ', 'gu-IN')
        end.to raise_error(StandardError)
      end

      context 'when country code is set in environment' do
        before do
          @original_country = Rails.application.config.country
          Rails.application.config.country = { sms_country_code: '+880' }
        end

        after do
          Rails.application.config.country = @original_country
        end

        let(:expected_sms_recipient_phone_number) { '+8808585858585' }

        it 'uses the set country code' do
          sms = SmsNotificationService.new(recipient_phone_number, sender_phone_number, twilio_client)
          expected_msg_default = 'Our staff at Simple Facility are thinking of you and your heart health. Our health team is always here if you have any follow-up questions or concerns.'

          expect(twilio_client).to receive_message_chain('messages.create').with(
            from: '+15005550006',
            to: expected_sms_recipient_phone_number,
            status_callback: '',
            body: /#{expected_msg_default}/
          )

          sms.send_reminder_sms('missed_visit_sms_reminder', appointment, '')
        end
      end
    end
  end
end
