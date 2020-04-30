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

        expected_msg = 'Our staff at Simple Facility are thinking of you and your heart health. Please continue your blood pressure medicines. Collect your medicine from the nearest sub centre. Contact your ANM or ASHA.'
        expect(twilio_client).to receive_message_chain('messages.create').with(from: '+15005550006',
                                                                               to: expected_sms_recipient_phone_number,
                                                                               status_callback: '',
                                                                               body: expected_msg)

        sms.send_reminder_sms('missed_visit_sms_reminder', appointment, '')
      end

      it 'should have the SMS body in Marathi' do
        sms = SmsNotificationService.new(recipient_phone_number, sender_phone_number, twilio_client)

        expected_msg = 'आमचे Simple Facility येथील कर्मचारी तुमच्‍याबद्दल आणि तुमच्‍या ह्रदयाच्‍या आरोग्‍याबद्दल विचार करीत आहेत. कृपया आपल्या रक्तदाबाची औषधे चालू ठेवा. जवळच्या उपकेंद्रामधून आपले औषध घ्या. आपल्या ANM किंवा ASHA शी संपर्क साधा.'
        expect(twilio_client).to receive_message_chain('messages.create').with(from: '+15005550006',
                                                                               to: expected_sms_recipient_phone_number,
                                                                               status_callback: '',
                                                                               body: expected_msg)

        sms.send_reminder_sms('missed_visit_sms_reminder', appointment, '', 'mr-IN')
      end

      it 'should have the SMS body in Punjabi' do
        sms = SmsNotificationService.new(recipient_phone_number, sender_phone_number, twilio_client)

        expected_msg = 'Simple Facility ਵਿਖੇ ਸਾਡਾ ਸਟਾਫ਼ ਤੁਹਾਡੇ ਅਤੇ ਤੁਹਾਡੇ ਦਿਲ ਦੀ ਸਿਹਤ ਬਾਰੇ ਸੋਚ ਰਿਹਾ ਹੈ। ਕਿਰਪਾ ਕਰਕੇ ਆਪਣੀਆਂ ਬਲੱਡ ਸ਼ੂਗਰ ਦਵਾਈਆਂ ਜਾਰੀ ਰੱਖੋ। ਨਜ਼ਦੀਕੀ ਉਪ ਕੇਂਦਰ ਤੋਂ ਆਪਣੀ ਦਵਾਈ ਇਕੱਤਰ ਕਰੋ। ਆਪਣੀ ANM ਜਾਂ ASHA ਨਾਲ ਸੰਪਰਕ ਕਰੋ।'
        expect(twilio_client).to receive_message_chain('messages.create').with(from: '+15005550006',
                                                                               to: expected_sms_recipient_phone_number,
                                                                               status_callback: '',
                                                                               body: expected_msg)

        sms.send_reminder_sms('missed_visit_sms_reminder', appointment, '', 'pa-Guru-IN')
      end

      it 'should have the SMS body in Kannada' do
        sms = SmsNotificationService.new(recipient_phone_number, sender_phone_number, twilio_client)

        expected_msg = 'Simple Facility ನಲ್ಲಿರುವ ನಮ್ಮ ಸಿಬ್ಬಂದಿ ನಿಮ್ಮ ಮತ್ತು ನಿಮ್ಮ ಹೃದಯದ ಆರೋಗ್ಯದ ಬಗ್ಗೆ ಯೋಚಿಸುತ್ತಿದ್ದಾರೆ. ದಯವಿಟ್ಟು ನಿಮ್ಮ ಬ್ಲಡ್ ಪ್ರೆಶರ್ ಔಷಧಗಳನ್ನು ಮುಂದುವರೆಸಿ. ನಿಮ್ಮ ಹತ್ತಿರದ ಉಪ ಕೇಂದ್ರದಲ್ಲಿ ನಿಮ್ಮ ಔಷಧಗಳನ್ನು ಸಂಗ್ರಹಿಸಿ. ನಿಮ್ಮ ANM ಅಥವಾ ASHA ಅವರನ್ನು ಸಂಪರ್ಕಿಸಿ.'
        expect(twilio_client).to receive_message_chain('messages.create').with(from: '+15005550006',
                                                                               to: expected_sms_recipient_phone_number,
                                                                               status_callback: '',
                                                                               body: expected_msg)

        sms.send_reminder_sms('missed_visit_sms_reminder', appointment, '', 'kn-IN')
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
          expected_msg_default = 'Our staff at Simple Facility are thinking of you and your heart health. Please continue your blood pressure medicines. Collect your medicine from the nearest sub centre. Contact your ANM or ASHA.'

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

  describe '#send_reminder_whatsapp' do
    context 'follow_up_reminder' do
      it 'should have the SMS body in the default locale' do
        sms = SmsNotificationService.new(recipient_phone_number, sender_phone_number, twilio_client)

        expected_msg_default = 'Our staff at Simple Facility are thinking of you and your heart health. Please continue your blood pressure medicines. Collect your medicine from the nearest sub centre. Contact your ANM or ASHA.'
        expect(twilio_client).to receive_message_chain('messages.create').with(from: 'whatsapp:+15005550006',
                                                                               to: "whatsapp:#{expected_sms_recipient_phone_number}",
                                                                               status_callback: '',
                                                                               body: expected_msg_default)

        sms.send_reminder_whatsapp('missed_visit_sms_reminder', appointment, '')
      end

      it 'should have the SMS body in Marathi' do
        sms = SmsNotificationService.new(recipient_phone_number, sender_phone_number, twilio_client)

        expected_msg_marathi = 'Our staff at Simple Facility are thinking of you and your heart health. Please continue your blood pressure medicines. Collect your medicine from the nearest sub centre. Contact your ANM or ASHA.'
        expect(twilio_client).to receive_message_chain('messages.create').with(from: 'whatsapp:+15005550006',
                                                                               to: "whatsapp:#{expected_sms_recipient_phone_number}",
                                                                               status_callback: '',
                                                                               body: expected_msg_marathi)

        sms.send_reminder_whatsapp('missed_visit_sms_reminder', appointment, '', 'mr-IN')
      end

      it 'should have the SMS body in Punjabi' do
        sms = SmsNotificationService.new(recipient_phone_number, sender_phone_number, twilio_client)

        expected_msg_punjabi = 'Our staff at Simple Facility are thinking of you and your heart health. Please continue your blood pressure medicines. Collect your medicine from the nearest sub centre. Contact your ANM or ASHA.'
        expect(twilio_client).to receive_message_chain('messages.create').with(from: 'whatsapp:+15005550006',
                                                                               to: "whatsapp:#{expected_sms_recipient_phone_number}",
                                                                               status_callback: '',
                                                                               body: expected_msg_punjabi)

        sms.send_reminder_whatsapp('missed_visit_sms_reminder', appointment, '', 'pa-Guru-IN')
      end

      it 'should raise an error if the locale for the SMS body is unsupported' do
        sms = SmsNotificationService.new(recipient_phone_number, sender_phone_number, twilio_client)

        expect do
          sms.send_reminder_whatsapp('missed_visit_sms_reminder', appointment, ' ', 'gu-IN')
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
          expected_msg_default = 'Our staff at Simple Facility are thinking of you and your heart health. Please continue your blood pressure medicines. Collect your medicine from the nearest sub centre. Contact your ANM or ASHA.'

          expect(twilio_client).to receive_message_chain('messages.create').with(
            from: 'whatsapp:+15005550006',
            to: "whatsapp:#{expected_sms_recipient_phone_number}",
            status_callback: '',
            body: /#{expected_msg_default}/
          )

          sms.send_reminder_whatsapp('missed_visit_sms_reminder', appointment, '')
        end
      end
    end
  end
end
