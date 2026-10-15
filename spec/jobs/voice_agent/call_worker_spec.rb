require "rails_helper"

RSpec.describe VoiceAgent::CallWorker do
  let(:appointment) { create(:appointment, scheduled_date: 10.days.ago) }
  let(:notification) do
    create(:notification,
      subject: appointment,
      patient: appointment.patient,
      purpose: "overdue_voice_call",
      status: "scheduled")
  end

  it "requests the call and marks the notification as sent" do
    communication = create(:communication, communication_type: "ai_voice_call")
    allow(Messaging::VoiceAgent::Call).to receive(:send_message) do |**, &block|
      block.call(communication)
      communication
    end

    described_class.new.perform(notification.id)

    expect(Messaging::VoiceAgent::Call).to have_received(:send_message).with(notification: notification)
    expect(notification.reload).to be_status_sent
    expect(communication.reload.notification).to eq(notification)
  end

  it "skips notifications that are no longer scheduled" do
    notification.status_cancelled!
    allow(Messaging::VoiceAgent::Call).to receive(:send_message)

    described_class.new.perform(notification.id)

    expect(Messaging::VoiceAgent::Call).not_to have_received(:send_message)
  end

  it "cancels the notification when a reference is missing" do
    allow(Messaging::VoiceAgent::Call).to receive(:send_message).and_raise(Messaging::MissingReferenceError.new("no phone"))

    described_class.new.perform(notification.id)

    expect(notification.reload).to be_status_cancelled
  end

  it "cancels the notification when the voice agent rejects the request" do
    allow(Messaging::VoiceAgent::Call).to receive(:send_message)
      .and_raise(Messaging::VoiceAgent::Error.new("bad request", reason: :invalid_request))

    described_class.new.perform(notification.id)

    expect(notification.reload).to be_status_cancelled
  end

  it "re-raises other voice agent errors so Sidekiq retries" do
    allow(Messaging::VoiceAgent::Call).to receive(:send_message)
      .and_raise(Messaging::VoiceAgent::Error.new("unavailable", reason: :server_error))

    expect { described_class.new.perform(notification.id) }.to raise_error(Messaging::VoiceAgent::Error)
    expect(notification.reload).to be_status_scheduled
  end
end
