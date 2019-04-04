require 'rails_helper'

RSpec.describe Api::Current::ExotelCallSessionsController, type: :controller do
  let!(:user) { create(:user, :with_sanitized_phone_number) }
  let!(:patient) { create(:patient, :with_sanitized_phone_number) }
  let!(:unknown_phone_number) { '1234567890' }
  let!(:invalid_patient_phone_number) { '1800-SIMPLE' }

  before(:each) do
    Rails.cache.clear
  end

  describe '#create' do
    context ':ok' do
      it 'should have a content-type set as text/plain' do
        get :create, params: { From: user.phone_number,
                               digits: patient.phone_numbers.first.number,
                               CallType: 'call-attempt',
                               CallSid: SecureRandom.uuid }

        expect(response.headers['Content-Type']).to eq('text/plain; charset=utf-8')
      end

      it 'should create an Exotel session if both the user and patient are registered' do
        get :create, params: { From: user.phone_number,
                               digits: patient.phone_numbers.first.number,
                               CallType: 'call-attempt',
                               CallSid: SecureRandom.uuid }

        expect(response).to have_http_status(200)
      end

      it { should use_after_action(:report_http_status) }
    end

    context ':forbidden' do
      it 'should have a content-type set as text/plain' do
        get :create, params: { From: unknown_phone_number,
                               digits: patient.phone_numbers.first.number,
                               CallType: 'call-attempt',
                               CallSid: SecureRandom.uuid }

        expect(response.headers['Content-Type']).to eq('text/plain; charset=utf-8')
      end

      it 'should not create an Exotel session if user is not registered' do
        get :create, params: { From: unknown_phone_number,
                               digits: patient.phone_numbers.first.number,
                               CallType: 'call-attempt',
                               CallSid: SecureRandom.uuid }

        expect(response).to have_http_status(403)
      end

      it 'should not create an Exotel session if the patient is not registered' do
        get :create, params: { From: user.phone_number,
                               digits: unknown_phone_number,
                               CallType: 'call-attempt',
                               CallSid: SecureRandom.uuid }

        expect(response).to have_http_status(403)
      end

      it { should use_after_action(:report_http_status) }
    end

    context ':bad_request' do
      it 'should allow only numeric strings as patient phone numbers' do
        get :create, params: { From: user.phone_number,
                               digits: invalid_patient_phone_number,
                               CallType: 'call-attempt',
                               CallSid: SecureRandom.uuid }

        expect(response).to have_http_status(400)
      end

      it { should use_after_action(:report_http_status) }
    end
  end

  describe '#fetch' do
    it 'should have a content-type set as text/plain' do
      get :fetch, params: { From: user.phone_number,
                            CallSid: SecureRandom.uuid }

      expect(response.headers['Content-Type']).to eq('text/plain; charset=utf-8')
    end

    context ':ok' do
      it 'should return the phone number of the Patient' do
        call_id = SecureRandom.uuid
        session = CallSession.new(call_id, user.phone_number, patient.phone_numbers.first.number)
        session.save

        get :fetch, params: { From: user.phone_number,
                              CallSid: call_id }

        expect(response.body).to eq(patient.phone_numbers.first.number)
      end

      it { should use_after_action(:report_http_status) }
    end

    context ':not_found' do
      it 'should return 404 if the session does not exist' do
        get :fetch, params: { From: user.phone_number,
                              CallSid: SecureRandom.uuid }

        expect(response).to have_http_status(404)
      end

      it { should use_after_action(:report_http_status) }
    end
  end

  describe '#terminate' do
    include ActiveJob::TestHelper

    let!(:call_id) { SecureRandom.uuid }

    before(:each) do
      allowed_call_result = { Call: { Sid: call_id } }
      allow_any_instance_of(ExotelAPIService).to receive(:call_details).with(call_id).and_return(allowed_call_result)
    end

    context ':ok' do
      before(:each) do
        session = CallSession.new(call_id, user.phone_number, patient.phone_numbers.first.number)
        session.save
      end

      it 'should delete the session and return 200 if the session exists' do
        get :terminate, params: { From: user.phone_number,
                                  CallSid: call_id,
                                  DialCallDuration: '10',
                                  CallType: 'call-attempt',
                                  CallStatus: 'completed' }

        fetched_session = CallSession.fetch(call_id)

        expect(fetched_session).to be_nil
        expect(response).to have_http_status(200)
      end

      it 'should report metrics to new relic' do
        expect(NewRelic::Agent).to receive(:increment_metric).with('exotel_call_sessions/call_type/call_attempt')
        expect(NewRelic::Agent).to receive(:increment_metric).with('exotel_call_sessions/call_status/completed')
        expect(NewRelic::Agent).to receive(:increment_metric).with('exotel_call_sessions/terminate/200')

        get :terminate, params: { From: user.phone_number,
                                  digits: patient.phone_numbers.first.number,
                                  CallType: 'call-attempt',
                                  CallSid: call_id,
                                  DialCallDuration: '10',
                                  CallStatus: 'completed' }
      end

      it { should use_after_action(:report_http_status) }

      it 'should schedule a job to log the call details' do
        assert_enqueued_with(job: ExotelCallDetailsJob, args: [call_id,
                                                               user.id,
                                                               patient.phone_numbers.first.number,
                                                               'completed']) do
          get :terminate, params: { From: user.phone_number,
                                    digits: patient.phone_numbers.first.number,
                                    CallType: 'call-attempt',
                                    CallSid: call_id,
                                    DialCallDuration: '10',
                                    CallStatus: 'completed' }
        end
      end
    end

    context ':not_found' do
      it 'should return 404 if the session does not exist' do
        get :terminate, params: { From: user.phone_number,
                                  CallSid: SecureRandom.uuid,
                                  DialCallDuration: '10',
                                  CallStatus: 'completed' }

        expect(response).to have_http_status(404)
      end

      it { should use_after_action(:report_http_status) }
    end
  end

  describe 'callbacks' do
    it 'should report http response codes to new relic' do
      expect(NewRelic::Agent).to receive(:increment_metric).with('exotel_call_sessions/create/200')

      get :create, params: { From: user.phone_number,
                             digits: patient.phone_numbers.first.number,
                             CallType: 'call-attempt',
                             CallSid: SecureRandom.uuid }
    end
  end
end
