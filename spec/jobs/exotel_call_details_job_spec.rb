require 'rails_helper'

RSpec.describe ExotelCallDetailsJob, type: :job do
  include ActiveJob::TestHelper

  let!(:user) { create(:user) }
  let!(:callee_phone_number) { Faker::PhoneNumber.phone_number }
  let!(:call_id) { SecureRandom.uuid }

  it 'should populate a call log' do
    allowed_call_result = OpenStruct.new({ Sid: call_id })
    allow_any_instance_of(ExotelAPIService).to receive(:call_details).with(call_id).and_return(allowed_call_result)

    assert_performed_jobs 1 do
      described_class.perform_later(call_id, user.id, callee_phone_number)
    end

    expect(CallLog.count).to eq(1)
  end

  it 'should not populate a call log if exotel api is unable to return call details' do
    allow_any_instance_of(ExotelAPIService).to receive(:call_details).with(call_id).and_return(nil)

    assert_performed_jobs 1 do
      described_class.perform_later(call_id, user.id, callee_phone_number)
    end

    expect(CallLog.count).to eq(0)
  end

  it 'should create a call log even the user does not exist' do
    allowed_call_result = OpenStruct.new({ Sid: call_id })
    allow_any_instance_of(ExotelAPIService).to receive(:call_details).with(call_id).and_return(allowed_call_result)

    assert_performed_jobs 1 do
      described_class.perform_later(call_id, SecureRandom.uuid, callee_phone_number)
    end

    expect(CallLog.count).to eq(1)
  end

  it 'makes attempts to retry when Exotel::HTTPError is raised' do
    allow_any_instance_of(described_class).to receive(:perform).and_raise(ExotelAPIService::HTTPError.new)
    expect_any_instance_of(described_class).to receive(:retry_job)

    assert_performed_jobs 1 do
      described_class.perform_later(call_id, user.id, callee_phone_number)
    end
  end
end

