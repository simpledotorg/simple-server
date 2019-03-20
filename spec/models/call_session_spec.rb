require 'rails_helper'

describe CallSession, type: :model do
  let!(:user) { create(:user, :with_sanitized_phone_number) }
  let!(:patient) { create(:patient, :with_sanitized_phone_number) }
  let!(:call_id) { SecureRandom.uuid }

  before(:each) do
    Rails.cache.clear
  end

  describe '#initialize' do
    it 'should strip leading 0 when looking up users by phone number' do
      user = create(:user, phone_number: '9876543210')

      session = CallSession.new(call_id, '09876543210', patient.phone_numbers.first.number)

      expect(session.user).to eq(user)
    end
  end

  describe '#authorized?' do
    it 'should return true if patient and user are both registered' do
      session = CallSession.new(call_id, user.phone_number, patient.phone_numbers.first.number)

      expect(session.authorized?).to be(true)
    end

    it 'should return false if user is not registered' do
      unknown_phone_number = Faker::PhoneNumber.phone_number

      session = CallSession.new(call_id, unknown_phone_number, patient.phone_numbers.first.number)

      expect(session.authorized?).to be(false)
    end

    it 'should return false if patient is not registered' do
      unknown_phone_number = Faker::PhoneNumber.phone_number

      session = CallSession.new(call_id, user.phone_number, unknown_phone_number)

      expect(session.authorized?).to be(false)
    end

    it 'should return false if the user is calling themselves' do
      session = CallSession.new(call_id, user.phone_number, user.phone_number)

      expect(session.authorized?).to be(false)
    end

    it 'should return false if the user is not approved for syncing' do
      user_without_sync_access = create(:user, :with_sanitized_phone_number, sync_approval_status: :requested)
      session = CallSession.new(call_id, user_without_sync_access.phone_number, patient.phone_numbers.first.number)

      expect(session.authorized?).to be(false)
    end
  end

  describe '#save' do
    it 'should save a call session against the call id' do
      call_id = SecureRandom.uuid
      expected_session = CallSession.new(call_id, user.phone_number, patient.phone_numbers.first.number)
      expected_session.save

      fetched_session = Rails.cache.fetch(CallSession.session_key(call_id))

      expect(fetched_session[:user_phone_number]).to eq(expected_session.user.phone_number)
      expect(fetched_session[:patient_phone_number]).to eq(expected_session.patient_phone_number.number)
    end
  end

  describe '#kill' do
    it 'should delete the existing call session stored against the call id' do
      call_id = SecureRandom.uuid
      expected_session = CallSession.new(call_id, user.phone_number, patient.phone_numbers.first.number)
      expected_session.save

      expect(expected_session.kill).to be(true)
      expect(Rails.cache.fetch(CallSession.session_key(call_id))).to be_nil
    end

    it 'should return a falsey value if a session does not exist against the call id' do
      call_id = SecureRandom.uuid
      expected_session = CallSession.new(call_id, user.phone_number, patient.phone_numbers.first.number)

      expect(expected_session.kill).to be_falsey
    end
  end

  describe '.fetch' do
    it 'should fetch an existing call session stored against the call id' do
      call_id = SecureRandom.uuid
      expected_session = CallSession.new(call_id, user.phone_number, patient.phone_numbers.first.number)
      expected_session.save

      fetched_session = CallSession.fetch(call_id)

      expect(fetched_session.patient_phone_number).to eq(patient.phone_numbers.first)
      expect(fetched_session.user).to eq(user)
    end

    it 'should return nil if a call session is not found' do
      call_id = SecureRandom.uuid
      expected_session = CallSession.new(call_id, user.phone_number, patient.phone_numbers.first.number)
      expected_session.save

      fetched_session = CallSession.fetch(SecureRandom.uuid)

      expect(fetched_session).to be_nil
    end
  end
end
