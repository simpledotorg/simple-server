require 'rails_helper'

RSpec.describe ExotelCallDetailsJob, type: :job do
  let!(:user) { create(:user) }
  let!(:callee_phone_number) { Faker::PhoneNumber.phone_number }

  it 'should populate a call log' do
    call_id = SecureRandom.uuid
    allowed_call_result = OpenStruct.new({ Sid: call_id })
    allow_any_instance_of(ExotelAPI).to receive(:call_details).with(call_id).and_return(allowed_call_result)

    expect {
      ExotelCallDetailsJob.perform_later(call_id, user.id, callee_phone_number)
    }.to change { CallLog.count }.by(1)
  end

  it 'should not populate a call log if exotel api is unable to return call details' do
    call_id = SecureRandom.uuid
    allow_any_instance_of(ExotelAPI).to receive(:call_details).with(call_id).and_return(nil)

    expect {
      ExotelCallDetailsJob.perform_later(call_id, user.id, callee_phone_number)
    }.to change { CallLog.count }.by(0)
  end

  it 'should create a call log even the user does not exist' do
    call_id = SecureRandom.uuid
    allowed_call_result = OpenStruct.new({ Sid: call_id })
    allow_any_instance_of(ExotelAPI).to receive(:call_details).with(call_id).and_return(allowed_call_result)

    expect {
      ExotelCallDetailsJob.perform_later(call_id, SecureRandom.uuid, callee_phone_number)
    }.to change { CallLog.count }.by(1)
  end
end

