require "rails_helper"

RSpec.describe VoiceAgent::OutcomeApplier do
  let(:detail) { create(:voice_call_detail, :with_communication) }
  let(:appointment) { detail.appointment }
  let(:bot_user) { VoiceAgentUser.find_or_create(org_id: appointment.facility.organization_id) }

  def apply(overrides = {})
    attributes = {
      call_request_id: detail.call_request_id,
      status: "completed",
      outcome: "agreed_to_visit",
      confidence: "high",
      safety_flag: false,
      attempts: 1,
      answered_attempts: 1,
      last_attempted_at: Time.current.iso8601,
      connected_seconds: 90,
      provider: "twilio"
    }.merge(overrides)
    described_class.call(detail, VoiceAgent::Outcome.new(attributes))
  end

  it "stores the outcome on the voice call detail" do
    apply(prompt_version: "bd-overdue-v3")

    expect(detail.reload).to have_attributes(
      status: "completed",
      outcome: "agreed_to_visit",
      confidence: "high",
      attempts: 1,
      provider: "twilio",
      prompt_version: "bd-overdue-v3"
    )
  end

  context "when the patient agreed to visit" do
    it "marks the appointment and records a call result by the voice agent user" do
      apply

      appointment.reload
      expect(appointment.agreed_to_visit).to eq(true)
      expect(appointment.remind_on).to eq(30.days.from_now.to_date)
      expect(appointment.call_results.last).to have_attributes(result_type: "agreed_to_visit", user_id: bot_user.id)
    end

    it "bumps device_updated_at so the server change wins the sync merge" do
      appointment.update!(device_updated_at: 2.days.ago)

      apply

      expect(appointment.reload.device_updated_at).to be_within(1.minute).of(Time.current)
    end
  end

  context "when the patient asked to be called later" do
    it "snoozes the appointment" do
      apply(outcome: "remind_to_call_later")

      appointment.reload
      expect(appointment.remind_on).to eq(7.days.from_now.to_date)
      expect(appointment.call_results.last.result_type).to eq("remind_to_call_later")
    end
  end

  context "when the classifier has low confidence" do
    it "treats an agreed_to_visit as remind_to_call_later" do
      apply(confidence: "low")

      expect(appointment.reload.call_results.last.result_type).to eq("remind_to_call_later")
      expect(appointment.agreed_to_visit).not_to eq(true)
    end

    it "treats a removal suggestion as remind_to_call_later" do
      apply(confidence: "low", outcome: "removal_suggested", suggested_remove_reason: "dead")

      expect(appointment.reload).to be_scheduled
      expect(appointment.call_results.last.result_type).to eq("remind_to_call_later")
      expect(appointment.patient.reload.status).not_to eq("dead")
    end
  end

  context "when the voice agent suggests removing the patient" do
    it "stores the suggestion without touching the appointment" do
      apply(outcome: "removal_suggested", suggested_remove_reason: "dead")

      expect(detail.reload.suggested_remove_reason).to eq("dead")
      expect(VoiceCallDetail.pending_review).to include(detail)
      expect(appointment.reload).to be_scheduled
      expect(appointment.call_results).to be_empty
      expect(appointment.patient.reload.status).not_to eq("dead")
    end
  end

  context "when the patient was unreached" do
    it "only records the outcome while not_responding removals are in shadow mode" do
      apply(status: "unreached", outcome: nil, confidence: nil, answered_attempts: 0, attempts: 3)

      expect(detail.reload).to be_status_unreached
      expect(appointment.reload).to be_scheduled
      expect(appointment.call_results).to be_empty
    end

    it "removes the appointment as not_responding when removals are enabled" do
      Flipper.enable(:voice_agent_not_responding_removals)

      apply(status: "unreached", outcome: nil, confidence: nil, answered_attempts: 0, attempts: 3)

      appointment.reload
      expect(appointment).to be_cancelled
      expect(appointment.cancel_reason).to eq("not_responding")
      expect(appointment.call_results.last).to have_attributes(
        result_type: "removed_from_overdue_list",
        remove_reason: "not_responding",
        user_id: bot_user.id
      )
    end
  end

  %w[failed expired].each do |status|
    context "when the call #{status}" do
      it "leaves the appointment on the overdue list" do
        Flipper.enable(:voice_agent_not_responding_removals)

        apply(status: status, outcome: nil, confidence: nil, answered_attempts: 0)

        expect(appointment.reload).to be_scheduled
        expect(appointment.remind_on).to be_nil
        expect(appointment.call_results).to be_empty
      end
    end
  end

  context "when a nurse or a visit got to the appointment first" do
    it "records the outcome but leaves the appointment unchanged" do
      appointment.update!(status: :visited)

      apply

      expect(detail.reload).to be_status_completed
      expect(appointment.reload).to be_visited
      expect(appointment.call_results).to be_empty
    end
  end

  context "when the patient reported an emergency" do
    it "applies the outcome and raises an alert" do
      allow(Sentry).to receive(:capture_message)

      apply(safety_flag: true)

      expect(detail.reload.safety_flag).to eq(true)
      expect(appointment.reload.agreed_to_visit).to eq(true)
      expect(Sentry).to have_received(:capture_message).with(
        "Voice agent safety flag",
        hash_including(extra: hash_including(voice_call_detail_id: detail.id, facility_id: appointment.facility_id))
      )
    end
  end

  context "when the outcome was already applied" do
    it "does nothing" do
      apply

      expect { apply(outcome: "remind_to_call_later") }.not_to change { appointment.reload.call_results.count }
      expect(detail.reload.outcome).to eq("agreed_to_visit")
    end

    it "reports that it was a duplicate" do
      expect(apply).to eq(:applied)
      expect(apply).to eq(:duplicate)
    end
  end
end
