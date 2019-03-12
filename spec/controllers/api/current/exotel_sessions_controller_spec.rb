require 'rails_helper'

RSpec.describe Api::Current::ExotelSessionsController, type: :controller do
  describe '#passthru' do
    let(:user) { create(:user) }
    let(:patient) { create(:patient) }
    let(:unknown_phone_number) { Faker::PhoneNumber.phone_number }

    context 'text/plain' do
      it 'should have a content-type set when returning 200' do
        get :passthru, params: { From: user.phone_number,
                                 digits: patient.phone_numbers.first.number,
                                 CallSid: SecureRandom.uuid }

        expect(response.headers['Content-Type']).to eq('text/plain')
      end

      it 'should have a content-type set when returning 403' do
          get :passthru, params: { From: unknown_phone_number,
                                   digits: patient.phone_numbers.first.number,
                                   CallSid: SecureRandom.uuid }

        expect(response.headers['Content-Type']).to eq('text/plain')
      end
    end

    it 'should create an Exotel session if both the user and patient are registered' do
      get :passthru, params: { From: user.phone_number,
                               digits: patient.phone_numbers.first.number,
                               CallSid: SecureRandom.uuid }

      expect(response).to have_http_status(200)
    end

    it 'should not create an Exotel session if user is not registered' do
      get :passthru, params: { From: unknown_phone_number,
                               digits: patient.phone_numbers.first.number,
                               CallSid: SecureRandom.uuid }

      expect(response).to have_http_status(403)
    end

    it 'should not create an Exotel session if the patient is not registered' do
      get :passthru, params: { From: user.phone_number,
                               digits: unknown_phone_number,
                               CallSid: SecureRandom.uuid }

      expect(response).to have_http_status(403)
    end
  end
end
