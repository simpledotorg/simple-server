require "rails_helper"

RSpec.describe VoiceCallSchedulerJob do
  let(:facility) { create(:facility) }
  let(:other_facility) { create(:facility) }

  def overdue_appointment(facility:, scheduled_date: 10.days.ago, patient: nil)
    patient ||= create(:patient, assigned_facility: facility)
    create(:appointment, patient: patient, facility: facility, scheduled_date: scheduled_date, status: :scheduled)
  end

  def voice_call_notifications
    Notification.where(purpose: "overdue_voice_call")
  end

  before do
    Sidekiq::Testing.fake!
    Flipper.enable(:voice_agent_calls, facility.region)
  end

  it "schedules a voice call for overdue, contactable patients at enabled facilities" do
    appointment = overdue_appointment(facility: facility)
    overdue_appointment(facility: other_facility)

    expect { described_class.perform_now }.to change(VoiceAgent::CallWorker.jobs, :size).by(1)

    expect(voice_call_notifications.count).to eq(1)
    notification = voice_call_notifications.first
    expect(notification).to have_attributes(subject: appointment, patient: appointment.patient, status: "scheduled")
    expect(VoiceAgent::CallWorker.jobs.last["args"]).to eq([notification.id])
  end

  it "does nothing when no facility is enabled" do
    Flipper.disable(:voice_agent_calls, facility.region)
    overdue_appointment(facility: facility)

    described_class.perform_now

    expect(voice_call_notifications).to be_empty
  end

  it "skips appointments that are not overdue enough" do
    overdue_appointment(facility: facility, scheduled_date: 1.day.ago)

    described_class.perform_now

    expect(voice_call_notifications).to be_empty
  end

  it "skips patients who have not consented to reminders" do
    patient = create(:patient, :denied, assigned_facility: facility)
    overdue_appointment(facility: facility, patient: patient)

    described_class.perform_now

    expect(voice_call_notifications).to be_empty
  end

  it "skips appointments that already have a voice call" do
    overdue_appointment(facility: facility)

    described_class.perform_now
    described_class.perform_now

    expect(voice_call_notifications.count).to eq(1)
  end

  it "still calls patients who were sent an SMS reminder" do
    appointment = overdue_appointment(facility: facility)
    create(:notification, subject: appointment, patient: appointment.patient, purpose: "missed_visit_reminder", status: "sent")

    described_class.perform_now

    expect(voice_call_notifications.count).to eq(1)
  end

  it "skips appointments with a recent call result" do
    appointment = overdue_appointment(facility: facility)
    create(:call_result, appointment: appointment, result_type: "remind_to_call_later", created_at: 2.days.ago)

    described_class.perform_now

    expect(voice_call_notifications).to be_empty
  end

  it "caps the number of calls per facility per day" do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("VOICE_AGENT_DAILY_CAP_PER_FACILITY", anything).and_return("2")
    3.times { overdue_appointment(facility: facility) }

    described_class.perform_now

    expect(voice_call_notifications.count).to eq(2)
  end
end
