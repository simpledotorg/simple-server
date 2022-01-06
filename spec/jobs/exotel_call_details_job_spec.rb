# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExotelCallDetailsJob, type: :job do
  include ActiveJob::TestHelper

  let!(:user_phone_number) { Faker::PhoneNumber.phone_number }
  let!(:callee_phone_number) { Faker::PhoneNumber.phone_number }
  let!(:call_id) { SecureRandom.uuid }

  let!(:stubbed_call_result) { "completed" }
  let!(:stubbed_call_duration) { 10 }
  let!(:stubbed_call_start_time) { "2017-02-17 14:16:03" }
  let!(:stubbed_call_end_time) { "2017-02-17 14:16:20" }
  let!(:stubbed_call_details) do
    {Call: {Sid: call_id,
            Duration: stubbed_call_duration,
            StartTime: stubbed_call_start_time,
            EndTime: stubbed_call_end_time}}
  end

  it "should populate a call log" do
    allow_any_instance_of(ExotelAPIService).to receive(:call_details).with(call_id).and_return(stubbed_call_details)

    assert_performed_jobs 1 do
      described_class.perform_later(call_id, user_phone_number, callee_phone_number, "completed")
    end

    expect(CallLog.count).to eq(1)
  end

  it "should populate a call log with the necessary details" do
    allow_any_instance_of(ExotelAPIService).to receive(:call_details).with(call_id).and_return(stubbed_call_details)

    perform_enqueued_jobs do
      described_class.perform_later(call_id, user_phone_number, callee_phone_number, "completed")
    end

    expect(CallLog.last.as_json.slice("result",
      "duration",
      "callee_phone_number",
      "caller_phone_number",
      "start_time",
      "end_time")).to eq("result" => stubbed_call_result,
        "duration" => stubbed_call_duration,
        "callee_phone_number" => callee_phone_number,
        "caller_phone_number" => user_phone_number,
        "start_time" => Time.zone.parse(stubbed_call_start_time),
        "end_time" => Time.zone.parse(stubbed_call_end_time))
  end

  it "should not populate a call log if exotel api is unable to return call details" do
    allow_any_instance_of(ExotelAPIService).to receive(:call_details).with(call_id).and_return(nil)

    assert_performed_jobs 1 do
      described_class.perform_later(call_id, user_phone_number, callee_phone_number, "failed")
    end

    expect(CallLog.count).to eq(0)
  end

  it "makes attempts to retry when Exotel::HTTPError is raised" do
    allow_any_instance_of(described_class).to receive(:perform).and_raise(ExotelAPIService::HTTPError.new)
    expect_any_instance_of(described_class).to receive(:retry_job)

    assert_performed_jobs 1 do
      described_class.perform_later(call_id, user_phone_number, callee_phone_number, "completed")
    end
  end
end
