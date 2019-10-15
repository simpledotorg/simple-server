require 'rails_helper'

RSpec.describe SmsNotificationService do
  let!(:facility_name) { 'Simple Facility' }
  let!(:appointment_scheduled_date) { Date.new(2018, 1, 1) }
  let!(:appointment) do
    create(:appointment,
           facility: create(:facility, name: facility_name),
           scheduled_date: appointment_scheduled_date)
  end

  context '#send_reminder_sms' do
    let(:twilio_client) { double('TwilioClientDouble') }
    let(:sender_phone_number) { ENV['TWILIO_PHONE_NUMBER'] }
    let(:recipient_phone_number) { '8585858585' }
    let(:expected_sms_recipient_phone_number) { '+918585858585' }

    context 'follow_up_reminder' do
      it 'should have the SMS body in the default locale' do
        sms = SmsNotificationService.new(recipient_phone_number, sender_phone_number, twilio_client)

        expected_msg_default = 'We missed you for your scheduled BP check-up at Simple Facility on 1 January, 2018.'\
        ' Please come between 9.30 AM and 2 PM.'

        expect(twilio_client).to receive_message_chain('messages.create').with(from: '+15005550006',
                                                                               to: expected_sms_recipient_phone_number,
                                                                               status_callback: '',
                                                                               body: expected_msg_default)

        sms.send_reminder_sms('missed_visit_sms_reminder', appointment, '')
      end

      it 'should have the SMS body in Marathi' do
        sms = SmsNotificationService.new(recipient_phone_number, sender_phone_number, twilio_client)

        expected_msg_marathi = 'दि. 1 जानेवारी, 2018 रोजी या दवाखान्यात Simple Facility ठरल्यानुसार बी. पी. चेक अप करून एक महिन्याचे औषध'\
        ' नेल्याचे दिसत नाही. कृपया सकाळी 9 ते दुपारी 12 या वेळेत येऊन बी. पी. चे औषध घेऊन जावे.'
        expect(twilio_client).to receive_message_chain('messages.create').with(from: '+15005550006',
                                                                               to: expected_sms_recipient_phone_number,
                                                                               status_callback: '',
                                                                               body: expected_msg_marathi)

        sms.send_reminder_sms('missed_visit_sms_reminder', appointment, '', 'mr-IN')
      end

      it 'should have the SMS body in Punjabi' do
        sms = SmsNotificationService.new(recipient_phone_number, sender_phone_number, twilio_client)

        expected_msg_punjabi = 'ਸਰਕਾਰੀ ਹਸਪਤਾਲ Simple Facility ਵਿੱਚ 1 ਜਨਵਰੀ, 2018 ਨੂੰ  ਤੁਹਾਡੇ ਬੀ.ਪੀ ਦੀ ਜਾਂਚ ਹੋਣੀ ਸੀ। ਕਿਰਪਾ ਕਰਕੇ'\
        ' 9:30 ਤੋਂ 2 ਵਜੇ ਦੇ ਵਿੱਚ ਆਉ।'
        expect(twilio_client).to receive_message_chain('messages.create').with(from: '+15005550006',
                                                                               to: expected_sms_recipient_phone_number,
                                                                               status_callback: '',
                                                                               body: expected_msg_punjabi)

        sms.send_reminder_sms('missed_visit_sms_reminder', appointment, '', 'pa-Guru-IN')
      end

      it 'should raise an error if the locale for the SMS body is unsupported' do
        sms = SmsNotificationService.new(recipient_phone_number, sender_phone_number, twilio_client)

        expect {
          sms.send_reminder_sms('missed_visit_sms_reminder', appointment, ' ', 'gu-IN')
        }.to raise_error(StandardError)
      end
    end
  end
end
