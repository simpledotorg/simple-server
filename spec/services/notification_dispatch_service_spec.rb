require "rails_helper"

RSpec.describe NotificationDispatchService do
  def mock_messaging_channel
    messaging_channel = Messaging::Channel
    allow(messaging_channel).to receive(:communication_type).and_return(:sms)
    allow(CountryConfig.current).to receive(:[]).and_call_original
    allow(CountryConfig.current).to receive(:[]).with(:appointment_reminders_channel).and_return(messaging_channel.to_s)
    messaging_channel
  end

  it "calls send_message on the messaging channel specified in country config" do
    notification = create(:notification)
    messaging_channel = mock_messaging_channel
    expect(messaging_channel).to receive(:send_message).with(
      recipient_number: notification.patient.latest_mobile_number,
      message: notification.localized_message
    )

    described_class.call(notification)
  end

  it "calls send_message for twilio with the right args supplied" do
    messaging_channel = Messaging::Twilio::Whatsapp
    allow(CountryConfig.current).to receive(:[]).and_call_original
    allow(CountryConfig.current).to receive(:[]).with(:appointment_reminders_channel).and_return(messaging_channel.to_s)

    notification = create(:notification)
    expect(messaging_channel).to receive(:send_message).with(
      recipient_number: notification.patient.latest_mobile_number,
      message: notification.localized_message
    )

    described_class.call(notification)
  end

  it "calls send_message for bsnl with the right args supplied" do
    messaging_channel = Messaging::Bsnl::Sms
    allow(CountryConfig.current).to receive(:[]).and_call_original
    allow(CountryConfig.current).to receive(:[]).with(:appointment_reminders_channel).and_return(messaging_channel.to_s)

    notification = create(:notification)
    expect(messaging_channel).to receive(:send_message).with(
      recipient_number: notification.patient.latest_mobile_number,
      dlt_template_name: notification.dlt_template_name,
      variable_content: notification.message_data[:variable_content]
    )

    described_class.call(notification)
  end

  it "accepts a messaging_channel as an override to the country config" do
    mock = mock_messaging_channel
    messaging_channel = Messaging::Bsnl::Sms
    notification = create(:notification)

    expect(mock).not_to receive(:send_message)
    expect(messaging_channel).to receive(:send_message)

    described_class.call(notification, messaging_channel: messaging_channel)
  end

  it "cancels notification when patient doesn't have a mobile number" do
    notification = create(:notification)
    notification.patient.phone_numbers.update_all(phone_type: :invalid)
    expect(mock_messaging_channel).not_to receive(:send_message)
    expect(Statsd.instance).to receive(:increment).with("notifications.skipped.no_mobile_number")

    described_class.call(notification)
    expect(notification.reload.status).to eq("cancelled")
  end

  it "cancels the notification if the messaging channel responds with invalid phone number error" do
    notification = create(:notification)
    messaging_channel = mock_messaging_channel
    allow(messaging_channel).to receive(:send_message).and_raise(Messaging::Twilio::Error.new("An error", 21211))
    expect(Statsd.instance).to receive(:increment).with("notifications.skipped.invalid_phone_number")

    described_class.call(notification)
    expect(notification.reload.status).to eq("cancelled")
  end

  it "cancels notifications if the phone number is missing and does not raise an error" do
    notification = create(:notification)
    notification.patient.phone_numbers.destroy_all

    described_class.call(notification)
    expect(notification.reload.status).to eq("cancelled")
  end

  it "passes a block to the communication channel that updates the notification in a transaction with communication creation" do
    notification = create(:notification)
    communication = create(:communication)
    messaging_channel = mock_messaging_channel

    allow(messaging_channel).to receive(:send_message) do |_, &block|
      block.call(communication)
    end

    described_class.call(notification)

    expect(notification.reload.status).to eq("sent")
    expect(notification.communications.first).to eq(communication)
  end
end
