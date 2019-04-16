require 'rails_helper'

RSpec.describe SmsNotificationService do
  context '#send_reminder_sms' do
    let(:facility_name) { 'Simple Facility' }
    let(:facility) { create(:facility, name: facility_name) }
    let(:appointment_scheduled_date) { Date.new(2018, 1, 1) }
    let(:appointment) { create(:appointment, scheduled_date: appointment_scheduled_date) }

    it 'should have the sms body in the default locale' do
      recipient_phone_number = '8585858585'

      twilio_client_double = double('TwilioClientDouble')
      sms = SmsNotificationService.new(recipient_phone_number, twilio_client_double)

      expected_msg_default = "We missed you for your scheduled BP check-up at Simple Facility on 1 January, 2018. Please come between 9.30 AM and 2 PM."
      expect(twilio_client_double).to receive_message_chain('messages.create').with(from: '+15005550006',
                                                                                    to: recipient_phone_number,
                                                                                    body: expected_msg_default)

      sms.send_reminder_sms(facility, appointment)
    end

    it 'should send a successful SMS in Marathi' do
      recipient_phone_number = '8585858585'

      twilio_client_double = double('TwilioClientDouble')
      sms = SmsNotificationService.new(recipient_phone_number, twilio_client_double)

      expected_msg_marathi = "दि. 1 जानेवारी, 2018 रोजी या दवाखान्यात Simple Facility ठरल्यानुसार बी. पी. चेक अप करून एक महिन्याचे औषध नेल्याचे दिसत नाही. कृपया सकाळी 9 ते दुपारी 12 या वेळेत येऊन बी. पी. चे औषध घेऊन जावे."
      expect(twilio_client_double).to receive_message_chain('messages.create').with(from: '+15005550006',
                                                                                    to: recipient_phone_number,
                                                                                    body: expected_msg_marathi)

      sms.send_reminder_sms(facility, appointment, :mr_IN)
    end
  end

  it 'should send a successful SMS in Punjabi' do
    recipient_phone_number = '8585858585'

    twilio_client_double = double('TwilioClientDouble')
    sms = SmsNotificationService.new(recipient_phone_number, twilio_client_double)

    expected_msg_punjabi = "ਅਸੀ ਤੁਹਾਨੂੰ 1 ਜਨਵਰੀ, 2018 ਨੂੰ ਸਰਕਾਰੀ ਹਸਪਤਾਲ Simple Facility ਵਿਚ ਤੁਹਾਡੇ ਨਿਰਧਾਰਿਤ ਬੀਪੀ ਚੈਕ-ਅਪ ਲਈ ਬੁਲਾਇਆ ਸੀ। ਤੁਸੀ 9.30 ਵਜੇ ਤੋਂ 2 ਵਜੇ ਦੇ ਵਿਚ ਆਓ।"
    expect(twilio_client_double).to receive_message_chain('messages.create').with(from: '+15005550006',
                                                                                  to: recipient_phone_number,
                                                                                  body: expected_msg_punjabi)

    sms.send_reminder_sms(facility, appointment, :pa_Guru_IN)
  end
end
