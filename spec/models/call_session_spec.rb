require 'rails_helper'

describe CallSession, type: :model do
  let!(:user) { create(:user) }
  let!(:patient) { create(:patient) }

  describe '#authorized?' do
    it 'should return true if patient and user are both registered' do
      session = CallSession.new(user.phone_number, patient.phone_numbers.first.number)

      expect(session.authorized?).to be(true)
    end

    it 'should return false if user is not registered' do
      unknown_phone_number = Faker::PhoneNumber.phone_number

      session = CallSession.new(unknown_phone_number, patient.phone_numbers.first.number)

      expect(session.authorized?).to be(false)
    end

    it 'should return false if patient is not registered' do
      unknown_phone_number = Faker::PhoneNumber.phone_number

      session = CallSession.new(user.phone_number, unknown_phone_number)

      expect(session.authorized?).to be(false)
    end

    it 'should return false if the user is calling themselves' do
      session = CallSession.new(user.phone_number, user.phone_number)

      expect(session.authorized?).to be(false)
    end
  end

  describe '.fetch' do
    it 'should fetch an existing call session stored against the call id' do
      call_id = SecureRandom.uuid
      expected_session = CallSession.new(user.phone_number, patient.phone_numbers.first.number)
      expected_session.save(call_id)

      fetched_session = CallSession.fetch(call_id)

      expect(fetched_session.patient_phone_number).to eq(patient.phone_numbers.first)
      expect(fetched_session.user).to eq(user)
    end

    it 'should return nil if a call session is not found' do
      call_id = SecureRandom.uuid
      expected_session = CallSession.new(user.phone_number, patient.phone_numbers.first.number)
      expected_session.save(call_id)

      fetched_session = CallSession.fetch(SecureRandom.uuid)

      expect(fetched_session).to be_nil
    end
  end
end
