require 'rails_helper'

RSpec.describe SmsNotificationService do
  VCR.configure do |config|
    config.cassette_library_dir = "spec/support/fixtures/cassettes"
    config.hook_into :webmock
  end

  context '#send_overdue_appointment_reminder_sms' do
    let(:facility_name) { 'Simple Facility' }
    let(:facility) { create(:facility, name: facility_name) }
    let(:appointment_scheduled_date) { Date.new(2018, 1, 1) }
    let(:appointment) { create(:appointment, scheduled_date: appointment_scheduled_date) }

    it 'should send a successful SMS in the default locale' do
      VCR.use_cassette("send_overdue_appointment_reminder_sms") do
        allow(I18n).to receive(:t).and_call_original
        allow(I18n).to receive(:t).with('sms.country_code').and_return('')

        user = create(:user, phone_number: '+918553427344')
        sms = SmsNotificationService.new(user)
        expected_sms_body = "We missed you for your scheduled BP check-up at Simple Facility on 1 January, 2018. Please come between 9.30 AM and 2 PM."

        expect(sms.send_reminder_sms(facility, appointment).body).to eq(expected_sms_body)
      end
    end
  end
end
