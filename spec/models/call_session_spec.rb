require 'rails_helper'

describe CallSession, type: :model do
  describe '#authorized?' do
    let!(:patient) { create(:patient) }
    let!(:user) { create(:user) }

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
end
