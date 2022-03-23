require "rails_helper"

RSpec.describe NotificationDispatchService do
  def mock_successful_delivery
    twilio_client = double("TwilioClientDouble")
    response_double = double("MessagingChannelResponse")

    allow(response_double).to receive(:status).and_return("queued")
    allow(response_double).to receive(:sid).and_return("1234")
    allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
    allow(twilio_client).to receive_message_chain("messages.create").and_return(response_double)
  end

  it "logs and cancels notification when patient doesn't have a mobile number" do
    notification.patient.phone_numbers.update_all(phone_type: :invalid)
    expect(Statsd.instance).to receive(:increment).with("notifications.skipped.no_mobile_number")
    expect {
      described_class.perform_async(notification.id)
      described_class.drain
    }.not_to change { Communication.count }
    expect(notification.reload.status).to eq("cancelled")
  end
  it "cancels the notification if twilio responds with invalid phone number error" do
    allow(Messaging::Twilio::ReminderSms).to receive(:send_message).and_raise(Messaging::Twilio::Error.new("An error", 21211))
    expect {
      described_class.perform_async(notification.id)
      described_class.drain
    }.not_to change { Communication.count }
    expect(notification.reload.status).to eq("cancelled")
  end

  it "cancels notifications if the phone number is missing" do
  end

  it "cancels notifications if the phone number is invalid and does not raise an error" do
  end

  it "calls send_message on the messaging channel supplied to the service" do
  end

  it "passes a block to the communication channel that updates the notification in a transaction with communication creation" do
    communication = create(:communication)
    allow(Messaging::Twilio::ReminderSms).to receive(:send_message) do |_, &block|
      block.call(communication)
    end

    described_class.perform_async(notification.id)
    described_class.drain
    expect(notification.reload.status).to eq("sent")
    expect(notification.communications.first).to eq(communication)
  end

  it "localizes the message based on facility state, not patient address" do
    mock_successful_delivery
    notification.patient.address.update!(state: "maharashtra")
    notification.subject.facility.update!(state: "punjab")
    localized_message = I18n.t(
      notification.message,
      {
        facility_name: notification.subject.facility.name,
        locale: "pa-Guru-IN"
      }
    )

    expect(Messaging::Twilio::ReminderSms).to receive(:send_message).with(
      recipient_number: notification.patient.latest_mobile_number,
      message: localized_message
    )
    described_class.perform_async(notification.id)
    described_class.drain
  end
end
