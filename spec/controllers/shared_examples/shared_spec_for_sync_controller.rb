require 'rails_helper'

def set_authentication_headers
  request.env['HTTP_X_USER_ID']     = request_user.id
  request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
end

RSpec.shared_examples 'a sync controller that authenticates user requests' do
  describe 'user api authentication' do
    describe 'SYNC_API_AUTHENTICATION feature is disabled' do
      let(:request_key) { model.to_s.underscore.pluralize }
      let(:empty_payload) { Hash[request_key, []] }

      before :each do
        request.env['X_USER_ID']          = 'invalid user id'
        request.env['HTTP_AUTHORIZATION'] = 'invalid access token'
      end

      before :each do
        ENV['ENABLE_SYNC_API_AUTHENTICATION'] = 'false'
      end

      it 'allows sync_from_user requests to the controller' do
        post :sync_from_user, params: empty_payload

        expect(response.status).not_to eq(401)
      end

      it 'allows sync_to_user requests to the controller' do
        post :sync_from_user, params: empty_payload

        expect(response.status).not_to eq(401)
      end
    end

    describe 'SYNC_API_AUTHENTICATION feature is enabled' do
      let(:request_key) { model.to_s.underscore.pluralize }
      let(:empty_payload) { Hash[request_key, []] }

      before :each do
        request_user = FactoryBot.create(:user)
        set_authentication_headers
      end

      before :each do
        ENV['ENABLE_SYNC_API_AUTHENTICATION'] = 'true'
      end

      it 'allows sync_from_user requests to the controller with valid user_id and access_token' do
        post :sync_from_user, params: empty_payload

        expect(response.status).not_to eq(401)
      end

      it 'allows sync_to_user requests to the controller with valid user_id and access_token' do
        get :sync_to_user, params: empty_payload

        expect(response.status).not_to eq(401)
      end

      it 'expires the user otp if not already expired on successful authentication' do
        get :sync_to_user, params: empty_payload

        request_user.reload
        expect(request_user.otp_valid?).to eq(false)
      end

      it 'sets user logged_in_at on successful authentication' do
        now = Time.now
        Timecop.freeze(now) do
          get :sync_to_user, params: empty_payload

          request_user.reload
          expect(request_user.logged_in_at.to_i).to eq(now.to_i)
        end
      end

      it 'does not allow sync_from_user requests to the controller with invalid user_id and access_token' do
        request.env['X_USER_ID']          = 'invalid user id'
        request.env['HTTP_AUTHORIZATION'] = 'invalid access token'
        post :sync_from_user, params: empty_payload

        expect(response.status).to eq(401)
      end

      it 'does not allow sync_to_user requests to the controller with invalid user_id and access_token' do
        request.env['X_USER_ID']          = 'invalid user id'
        request.env['HTTP_AUTHORIZATION'] = 'invalid access token'
        get :sync_to_user, params: empty_payload

        expect(response.status).to eq(401)
      end
    end
  end
end

RSpec.shared_examples 'a working sync controller creating records' do
  let(:request_key) { model.to_s.underscore.pluralize }
  let(:empty_payload) { Hash[request_key, []] }

  let(:new_records) { (1..10).map { build_payload.call } }
  let(:new_records_payload) { Hash[request_key, new_records] }


  let(:invalid_payload) { Hash[request_key, [invalid_record]] }

  let(:invalid_records_payload) { (1..5).map { build_invalid_payload.call } }
  let(:valid_records_payload) { (1..5).map { build_payload.call } }
  let(:partially_valid_payload) { Hash[request_key, invalid_records_payload + valid_records_payload] }

  before :each do
    set_authentication_headers if defined? request_user
  end

  describe 'creates new records' do
    it 'returns 400 when there are no records in the request' do
      post(:sync_from_user, params: empty_payload)
      expect(response.status).to eq 400
    end

    it 'creates new records without any associations' do
      post(:sync_from_user, params: new_records_payload, as: :json)
      expect(model.count).to eq 10
      expect(response).to have_http_status(200)
    end

    it 'returns errors for invalid records' do
      post(:sync_from_user, params: invalid_payload, as: :json)

      response_errors = JSON(response.body)['errors'].first
      expect(response_errors).to be_present
      expect(response_errors['schema']).to be_present
      expect(response_errors['id']).to be_present
      expect(response_errors['schema'].count).to eq number_of_schema_errors_in_invalid_payload
    end

    it 'returns errors for some invalid records, and accepts others' do
      post(:sync_from_user, params: partially_valid_payload, as: :json)

      response_errors = JSON(response.body)['errors']
      expect(response_errors.count).to eq 5
      expect(response_errors.map { |error| error['id'] })
        .to match_array(invalid_records_payload.map { |record| record['id'] })

      expect(model.count).to eq 5
      expect(model.pluck(:id))
        .to match_array(valid_records_payload.map { |record| record['id'] })
    end
  end
end

RSpec.shared_examples 'a working sync controller updating records' do
  let(:request_key) { model.to_s.underscore.pluralize }
  let(:existing_records) { FactoryBot.create_list(model.to_s.underscore.to_sym, 10) }
  let(:updated_records) { existing_records.map(&update_payload) }
  let(:updated_payload) { Hash[request_key, updated_records] }

  before :each do
    set_authentication_headers if defined? request_user
  end

  describe 'updates records' do
    it 'with updated record attributes' do
      post :sync_from_user, params: updated_payload, as: :json

      updated_records.each do |record|
        db_record = model.find(record['id'])
        expect(db_record.attributes.with_payload_keys.with_int_timestamps)
          .to eq(record.to_json_and_back.with_int_timestamps)
      end
    end
  end
end

RSpec.shared_examples 'a working sync controller sending records' do
  before :each do
    Timecop.travel(15.minutes.ago) do
      FactoryBot.create_list(model.to_s.underscore, 10)
    end
  end

  before :each do
    set_authentication_headers if defined? request_user
  end

  describe 'GET sync: send data from server to device;' do
    let(:response_key) { model.to_s.underscore.pluralize }
    it 'Returns records from the beginning of time, when processed_since is not set' do
      get :sync_to_user

      response_body = JSON(response.body)
      expect(response_body[response_key].count).to eq model.count
      expect(response_body[response_key].map { |record| record['id'] }.to_set)
        .to eq(model.all.pluck(:id).to_set)
    end

    it 'Returns new records added since last sync' do
      expected_records = FactoryBot.create_list(model.to_s.underscore, 5, updated_at: 5.minutes.ago)
      get :sync_to_user, params: { processed_since: 10.minutes.ago }

      response_body = JSON(response.body)
      expect(response_body[response_key].count).to eq 5

      expect(response_body[response_key].map { |record| record['id'] }.to_set)
        .to eq(expected_records.map(&:id).to_set)

      expect(response_body['processed_since'].to_time.to_i)
        .to eq(expected_records.map(&:updated_at).max.to_i)
    end

    it 'Returns an empty list when there is nothing to sync' do
      sync_time = 10.minutes.ago
      get :sync_to_user, params: { processed_since: sync_time }
      response_body = JSON(response.body)
      expect(response_body[response_key].count).to eq 0
      expect(response_body['processed_since'].to_time.to_i).to eq sync_time.to_i
    end

    describe 'batching' do
      it 'returns the number of records requested with limit' do
        get :sync_to_user, params: {
          processed_since: 20.minutes.ago,
          limit:           2
        }
        response_body = JSON(response.body)
        expect(response_body[response_key].count).to eq 2
      end

      it 'Returns all the records on server over multiple small batches' do
        get :sync_to_user, params: {
          processed_since: 20.minutes.ago,
          limit:           7
        }
        response_1 = JSON(response.body)

        get :sync_to_user, params: {
          processed_since: response_1['processed_since'],
          limit:           7
        }
        response_2 = JSON(response.body)

        received_records = response_1[response_key].concat(response_2[response_key]).to_set
        expect(received_records.count).to eq model.count

        expect(received_records.map { |record| record['id'] }.to_set)
          .to eq(model.all.pluck(:id).to_set)
      end
    end
  end
end