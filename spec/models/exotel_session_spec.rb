require 'rails_helper'

describe ExotelSession, type: :model do
  describe '#passthru?' do
    it 'should return true if patient and user are both registered' do
      patient = create(:patient)
      user = create(:user)

      session = ExotelSession.new(user.phone_number, patient.phone_numbers.first.number)

      expect(session.passthru?).to be(true)
    end

    it 'should return false if user is not registered' do
      patient = create(:patient)
      unknown_phone_number = Faker::PhoneNumber.phone_number

      session = ExotelSession.new(unknown_phone_number, patient.phone_numbers.first.number)

      expect(session.passthru?).to be(false)
    end

    it 'should return false if patient is not registered' do
      user = create(:user)
      unknown_phone_number = Faker::PhoneNumber.phone_number

      session = ExotelSession.new(user.phone_number, unknown_phone_number)

      expect(session.passthru?).to be(false)
    end
  end
end
