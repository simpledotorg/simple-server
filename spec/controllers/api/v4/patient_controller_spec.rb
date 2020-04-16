require 'rails_helper'

RSpec.describe Api::V4::PatientController, type: :controller do
  describe '#request_otp' do
    let!(:bp_passport) { create(:patient_business_identifier, identifier_type: 'simple_bp_passport') }
    let(:patient) { bp_passport.patient }
    let!(:passport_authentication) { create(:passport_authentication, patient_business_identifier: bp_passport) }

    before do
      allow(SendPatientOtpSmsJob).to receive(:perform_later)
    end

    it 'returns a successful response' do
      post :request_otp, params: { passport_id: bp_passport.identifier }
      expect(response.status).to eq(200)
    end

    it 'send an OTP SMS' do
      expect(SendPatientOtpSmsJob).to receive(:perform_later).with(passport_authentication)
      post :request_otp, params: { passport_id: bp_passport.identifier }
    end

    context 'when BP passport ID does not exist' do
      it 'returns a 404 response' do
        post :request_otp, params: { passport_id: 'some-identifier' }
        expect(response.status).to eq(404)
      end
    end

    context 'when patient does not have any mobile numbers' do
      it 'returns a 404 response' do
        patient.phone_numbers.destroy_all

        post :request_otp, params: { passport_id: bp_passport.identifier }
        expect(response.status).to eq(404)
      end
    end
  end

  describe '#activate' do
    let!(:bp_passport) { create(:patient_business_identifier, identifier_type: 'simple_bp_passport') }
    let(:patient) { bp_passport.patient }
    let!(:passport_authentication) { create(:passport_authentication, patient_business_identifier: bp_passport) }

    it 'returns a successful response' do
      post :activate, params: { passport_id: bp_passport.identifier, otp: passport_authentication.otp }
      expect(response.status).to eq(200)

      response_data = JSON.parse(response.body)
      expect(response_data).to match(
        "access_token" => passport_authentication.reload.access_token,
        "patient_id" => patient.id
      )
    end

    context 'when otp is wrong' do
      it 'returns an unauthorized response' do
        post :activate, params: { passport_id: bp_passport.identifier, otp: 'wrong-otp' }
        expect(response.status).to eq(401)
      end
    end

    context 'when BP passport ID is wrong' do
      it 'returns an unauthorized response' do
        post :activate, params: { passport_id: 'wrong-identifier', otp: passport_authentication.otp }
        expect(response.status).to eq(401)
      end
    end

    context 'when an OTP is expired' do
      before { passport_authentication.tap(&:expire_otp).save! }

      it 'returns an unauthorized response' do
        post :activate, params: { passport_id: bp_passport.identifier, otp: passport_authentication.otp }
        expect(response.status).to eq(401)
      end
    end

    context 'when an OTP is re-used' do
      it 'returns an unauthorized response' do
        post :activate, params: { passport_id: bp_passport.identifier, otp: passport_authentication.otp }
        post :activate, params: { passport_id: bp_passport.identifier, otp: passport_authentication.otp }

        expect(response.status).to eq(401)
      end
    end
  end
end
