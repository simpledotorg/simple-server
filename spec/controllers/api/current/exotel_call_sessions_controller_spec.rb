require 'rails_helper'

RSpec.describe Api::Current::ExotelCallSessionsController, type: :controller do
  describe '#create' do
    let!(:user) { create(:user) }
    let!(:patient) { create(:patient, :with_sanitized_phone_number) }
    let!(:unknown_phone_number) { '1234567890' }
    let!(:invalid_patient_phone_number) { '1800-SIMPLE' }

    context ':ok' do
      it 'should have a content-type set as text/plain' do
        get :create, params: { From: user.phone_number,
                               digits: patient.phone_numbers.first.number,
                               CallSid: SecureRandom.uuid }

        expect(response.headers['Content-Type']).to eq('text/plain')
      end

      it 'should create an Exotel session if both the user and patient are registered' do
        get :create, params: { From: user.phone_number,
                               digits: patient.phone_numbers.first.number,
                               CallSid: SecureRandom.uuid }

        expect(response).to have_http_status(200)
      end

      it 'should report metrics to new relic' do
        expect(NewRelic::Agent).to receive(:increment_metric).with("exotel_call_sessions/create/200")

        get :create, params: { From: user.phone_number,
                               digits: patient.phone_numbers.first.number,
                               CallSid: SecureRandom.uuid }
      end
    end

    context ':forbidden' do
      it 'should have a content-type set as text/plain' do
        get :create, params: { From: unknown_phone_number,
                               digits: patient.phone_numbers.first.number,
                               CallSid: SecureRandom.uuid }

        expect(response.headers['Content-Type']).to eq('text/plain')
      end

      it 'should not create an Exotel session if user is not registered' do
        get :create, params: { From: unknown_phone_number,
                               digits: patient.phone_numbers.first.number,
                               CallSid: SecureRandom.uuid }

        expect(response).to have_http_status(403)
      end

      it 'should not create an Exotel session if the patient is not registered' do
        get :create, params: { From: user.phone_number,
                               digits: unknown_phone_number,
                               CallSid: SecureRandom.uuid }

        expect(response).to have_http_status(403)
      end

      it 'should report metrics to new relic' do
        expect(NewRelic::Agent).to receive(:increment_metric).with("exotel_call_sessions/create/403")

        get :create, params: { From: unknown_phone_number,
                               digits: patient.phone_numbers.first.number,
                               CallSid: SecureRandom.uuid }
      end
    end

    context ':bad_request' do
      it 'should allow only numeric strings as patient phone numbers' do
        get :create, params: { From: user.phone_number,
                               digits: invalid_patient_phone_number,
                               CallSid: SecureRandom.uuid }

        expect(response).to have_http_status(400)
      end

      it 'should report metrics to new relic' do
        expect(NewRelic::Agent).to receive(:increment_metric).with("exotel_call_sessions/create/400")

        get :create, params: { From: user.phone_number,
                               digits: invalid_patient_phone_number,
                               CallSid: SecureRandom.uuid }
      end
    end
  end
end
