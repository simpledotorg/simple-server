require "rails_helper"

RSpec.describe VoiceAgent::Outcome do
  def outcome(overrides = {})
    described_class.new({
      call_request_id: "abc-123",
      status: "completed",
      outcome: "agreed_to_visit",
      suggested_remove_reason: nil,
      safety_flag: false,
      confidence: "high",
      attempts: 2,
      answered_attempts: 1,
      last_attempted_at: "2026-09-15T11:32:10+06:00",
      connected_seconds: 118,
      provider: "twilio",
      prompt_version: "bd-overdue-v3"
    }.merge(overrides))
  end

  it "is valid for a completed call" do
    expect(outcome).to be_valid
  end

  it "requires a known status" do
    expect(outcome(status: nil)).not_to be_valid
    expect(outcome(status: "ringing")).not_to be_valid
  end

  it "requires an outcome and a confidence for completed calls" do
    expect(outcome(outcome: nil)).not_to be_valid
    expect(outcome(confidence: nil)).not_to be_valid
    expect(outcome(outcome: "removed_from_overdue_list")).not_to be_valid
    expect(outcome(confidence: "medium")).not_to be_valid
  end

  it "rejects an outcome for calls that did not complete" do
    expect(outcome(status: "unreached", outcome: nil, confidence: nil)).to be_valid
    expect(outcome(status: "unreached", outcome: "agreed_to_visit")).not_to be_valid
  end

  describe "removal suggestions" do
    it "requires a suggested remove reason" do
      expect(outcome(outcome: "removal_suggested")).not_to be_valid
      expect(outcome(outcome: "removal_suggested", suggested_remove_reason: "moved")).to be_valid
    end

    it "only accepts reasons a nurse can confirm from a call" do
      expect(outcome(outcome: "removal_suggested", suggested_remove_reason: "not_responding")).not_to be_valid
      expect(outcome(outcome: "removal_suggested", suggested_remove_reason: "other")).not_to be_valid
    end

    it "rejects a suggested remove reason for other outcomes" do
      expect(outcome(suggested_remove_reason: "moved")).not_to be_valid
    end
  end

  it "requires non-negative integer counters" do
    expect(outcome(attempts: -1)).not_to be_valid
    expect(outcome(answered_attempts: "two")).not_to be_valid
    expect(outcome(connected_seconds: 1.5)).not_to be_valid
  end

  it "requires a parseable last_attempted_at when present" do
    expect(outcome(last_attempted_at: "yesterday-ish")).not_to be_valid
    expect(outcome(last_attempted_at: nil)).to be_valid
  end

  it "casts safety_flag to a boolean" do
    expect(outcome(safety_flag: "true").safety_flag).to eq(true)
    expect(outcome(safety_flag: nil).safety_flag).to eq(false)
  end

  it "exposes the attributes to store on the voice call detail" do
    expect(outcome.detail_attributes).to include(
      status: "completed",
      outcome: "agreed_to_visit",
      safety_flag: false,
      confidence: "high",
      attempts: 2,
      answered_attempts: 1,
      connected_seconds: 118,
      provider: "twilio",
      prompt_version: "bd-overdue-v3"
    )
    expect(outcome.detail_attributes[:last_attempted_at]).to eq(Time.zone.parse("2026-09-15T11:32:10+06:00"))
  end
end
