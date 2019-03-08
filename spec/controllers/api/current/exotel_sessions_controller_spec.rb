require 'rails_helper'

RSpec.describe Api::Current::ExotelSessionsController, type: :controller do
  describe '#passthru' do
    it 'should create an Exotel session if both the user and patient are registered' do
      user = create(:user)
      patient = create(:patient)

      get :passthru, params: { From: user.phone_number,
                               digits: patient.phone_numbers.first.number,
                               CallSid: SecureRandom.uuid }

      expect(response).to have_http_status(200)
    end

    it 'should not create an Exotel session if user is not registered' do
      create(:user)
      patient = create(:patient)

      get :passthru, params: { From: Faker::PhoneNumber.phone_number,
                               digits: patient.phone_numbers.first.number,
                               CallSid: SecureRandom.uuid }

      expect(response).to have_http_status(403)
    end

    it 'should not create an Exotel session if the patient is not registered' do
      user = create(:user)
      create(:patient)

      get :passthru, params: { From: user.phone_number,
                               digits: Faker::PhoneNumber.phone_number,
                               CallSid: SecureRandom.uuid }

      expect(response).to have_http_status(403)
    end
  end
end
