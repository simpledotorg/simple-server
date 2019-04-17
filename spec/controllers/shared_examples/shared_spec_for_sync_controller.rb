require 'rails_helper'

def set_authentication_headers
  request.env['HTTP_X_USER_ID'] = request_user.id
  request.env['HTTP_X_FACILITY_ID'] = request_facility.id if defined? request_facility
  request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
end

def make_process_token(params)
  Base64.encode64(params.to_json)
end

def parse_process_token(response_body)
  JSON.parse(Base64.decode64(response_body['process_token'])).with_indifferent_access
end

RSpec.shared_examples 'a sync controller that authenticates user requests' do
  describe 'user api authentication' do
    let(:request_key) { model.to_s.underscore.pluralize }
    let(:empty_payload) { Hash[request_key, []] }

    before :each do
      request_user = FactoryBot.create(:user)
      set_authentication_headers
    end

    it 'allows sync_from_user requests to the controller with valid user_id and access_token' do
      post :sync_from_user, params: empty_payload

      expect(response.status).not_to eq(401)
    end

    it 'allows sync_to_user requests to the controller with valid user_id and access_token' do
      get :sync_to_user, params: empty_payload

      expect(response.status).not_to eq(401)
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
      request.env['X_USER_ID'] = 'invalid user id'
      request.env['HTTP_AUTHORIZATION'] = 'invalid access token'
      post :sync_from_user, params: empty_payload

      expect(response.status).to eq(401)
    end

    it 'does not allow sync_to_user requests to the controller with invalid user_id and access_token' do
      request.env['X_USER_ID'] = 'invalid user id'
      request.env['HTTP_AUTHORIZATION'] = 'invalid access token'
      get :sync_to_user, params: empty_payload

      expect(response.status).to eq(401)
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
    set_authentication_headers
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
  let(:existing_records) { create_record_list(10) }
  let(:updated_records) { existing_records.map(&update_payload) }
  let(:updated_payload) { Hash[request_key, updated_records] }

  before :each do
    set_authentication_headers
  end

  describe 'updates records' do
    it 'with updated record attributes' do
      post :sync_from_user, params: updated_payload, as: :json

      updated_records.each do |record|
        db_record = model.find(record['id'])
        expect(db_record.attributes.to_json_and_back.with_payload_keys.with_int_timestamps)
          .to eq(record.to_json_and_back.with_int_timestamps)
      end
    end
  end
end

RSpec.shared_examples 'a working V1 sync controller sending records' do
  before :each do
    Timecop.travel(15.minutes.ago) do
      create_record_list(10)
    end
  end

  before :each do
    set_authentication_headers
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
      expected_records = create_record_list(5, updated_at: 5.minutes.ago)
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
          limit: 2
        }
        response_body = JSON(response.body)
        expect(response_body[response_key].count).to eq 2
      end

      it 'Returns all the records on server over multiple small batches' do
        get :sync_to_user, params: {
          processed_since: 20.minutes.ago,
          limit: 7
        }
        response_1 = JSON(response.body)

        get :sync_to_user, params: {
          processed_since: response_1['processed_since'],
          limit: 7
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

RSpec.shared_examples 'a working V2 sync controller sending records' do
  before :each do
    Timecop.travel(15.minutes.ago) do
      create_record_list(5)
    end
    Timecop.travel(14.minutes.ago) do
      create_record_list(5)
    end
  end

  before :each do
    set_authentication_headers
  end

  describe 'GET sync: send data from server to device;' do
    let(:response_key) { model.to_s.underscore.pluralize }
    it 'Returns records from the beginning of time, when process_token is not set' do
      get :sync_to_user

      response_body = JSON(response.body)
      expect(response_body[response_key].count).to eq model.count
      expect(response_body[response_key].map { |record| record['id'] }.to_set)
        .to eq(model.all.pluck(:id).to_set)
    end

    it 'Returns new records added since last sync' do
      expected_records = create_record_list(5, updated_at: 5.minutes.ago)
      get :sync_to_user, params: { process_token: make_process_token({ other_facilities_processed_since: 10.minutes.ago }) }

      response_body = JSON(response.body)
      expect(response_body[response_key].count).to eq 5

      expect(response_body[response_key].map { |record| record['id'] }.to_set)
        .to eq(expected_records.map(&:id).to_set)

      response_process_token = parse_process_token(response_body)
      expect(response_process_token[:other_facilities_processed_since].to_time.to_i)
        .to eq(expected_records.map(&:updated_at).max.to_i)
    end

    it 'Returns an empty list when there is nothing to sync' do
      sync_time = 10.minutes.ago
      get :sync_to_user, params: { process_token: make_process_token({ other_facilities_processed_since: sync_time }) }
      response_body = JSON(response.body)
      response_process_token = parse_process_token(response_body)
      expect(response_body[response_key].count).to eq 0
      expect(response_process_token[:other_facilities_processed_since].to_time.to_i).to eq sync_time.to_i
    end

    describe 'batching' do
      it 'returns the number of records requested with limit' do
        get :sync_to_user, params: {
          process_token: make_process_token({ other_facilities_processed_since: 20.minutes.ago }),
          limit: 2
        }
        response_body = JSON(response.body)
        expect(response_body[response_key].count).to eq 2
      end

      it 'Returns all the records on server over multiple small batches' do
        get :sync_to_user, params: {
          process_token: make_process_token({ other_facilities_processed_since: 20.minutes.ago }),
          limit: 7
        }

        response_1 = JSON(response.body)

        get :sync_to_user, params: {
          process_token: response_1['process_token'],
          limit: 8
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

RSpec.shared_examples 'a working Current sync controller sending records' do
  before :each do
    Timecop.travel(15.minutes.ago) do
      create_record_list(5)
    end
    Timecop.travel(14.minutes.ago) do
      create_record_list(5)
    end
  end

  before :each do
    set_authentication_headers
  end

  describe 'GET sync: send data from server to device;' do
    let(:response_key) { model.to_s.underscore.pluralize }
    it 'Returns records from the beginning of time, when process_token is not set' do
      get :sync_to_user

      response_body = JSON(response.body)
      expect(response_body[response_key].count).to eq model.count
      expect(response_body[response_key].map { |record| record['id'] }.to_set)
        .to eq(model.all.pluck(:id).to_set)
    end

    it 'Returns new records added since last sync' do
      expected_records = create_record_list(5, updated_at: 5.minutes.ago)
      get :sync_to_user, params: { process_token: make_process_token({ other_facilities_processed_since: 10.minutes.ago }) }

      response_body = JSON(response.body)
      expect(response_body[response_key].count).to eq 5

      expect(response_body[response_key].map { |record| record['id'] }.to_set)
        .to eq(expected_records.map(&:id).to_set)

      response_process_token = parse_process_token(response_body)
      expect(response_process_token[:other_facilities_processed_since].to_time.to_i)
        .to eq(expected_records.map(&:updated_at).max.to_i)
    end

    it 'Returns an empty list when there is nothing to sync' do
      sync_time = 10.minutes.ago
      get :sync_to_user, params: { process_token: make_process_token({ other_facilities_processed_since: sync_time }) }
      response_body = JSON(response.body)
      response_process_token = parse_process_token(response_body)
      expect(response_body[response_key].count).to eq 0
      expect(response_process_token[:other_facilities_processed_since].to_time.to_i).to eq sync_time.to_i
    end

    describe 'batching' do
      it 'returns the number of records requested with limit' do
        get :sync_to_user, params: {
          process_token: make_process_token({ other_facilities_processed_since: 20.minutes.ago }),
          limit: 2
        }
        response_body = JSON(response.body)
        expect(response_body[response_key].count).to eq 2
      end

      it 'Returns all the records on server over multiple small batches' do
        get :sync_to_user, params: {
          process_token: make_process_token({ other_facilities_processed_since: 20.minutes.ago }),
          limit: 7
        }

        response_1 = JSON(response.body)

        get :sync_to_user, params: {
          process_token: response_1['process_token'],
          limit: 8
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
RSpec.shared_examples 'a sync controller that audits the data access' do
  include ActiveJob::TestHelper

  before :each do
    set_authentication_headers
  end

  let(:auditable_type) { model.to_s }
  let(:request_key) { model.to_s.underscore.pluralize }
  let(:model_class_sym) { model.to_s.underscore.to_sym }

  describe 'creates an audit log for data synced from user' do
    let(:record) { build_payload.call }
    let(:payload) { Hash[request_key, [record]] }

    it 'creates an audit log for new data created by the user' do
      post :sync_from_user, params: payload, as: :json

      audit_logs = AuditLog.where(user_id: request_user.id, auditable_type: auditable_type, auditable_id: record[:id])
      expect(audit_logs.count).to eq 1
      expect(audit_logs.first.action).to eq('create')
    end

    it 'creates an audit log for data updated by the user' do
      exiting_record = create_record
      record[:id] = exiting_record.id
      payload[request_key] = [record]

      post :sync_from_user, params: payload, as: :json

      audit_logs = AuditLog.where(user_id: request_user.id, auditable_type: auditable_type, auditable_id: record[:id])
      expect(audit_logs.count).to be 1
      expect(audit_logs.first.action).to eq('update')
    end

    it 'creates an audit log for data touched by the user' do
      exiting_record = create_record
      record[:id] = exiting_record.id
      record[:updated_at] = 3.days.ago
      payload[request_key] = [record]

      post :sync_from_user, params: payload, as: :json

      audit_logs = AuditLog.where(user_id: request_user.id, auditable_type: auditable_type, auditable_id: record[:id])
      expect(audit_logs.count).to be 1
      expect(audit_logs.first.action).to eq('touch')
    end
  end

  describe 'creates an audit log for data synced to user' do
    let!(:records) { create_record_list(5) }
    it 'creates an audit log for data fetched by the user' do
      perform_enqueued_jobs do
        get :sync_to_user, params: {
          processed_since: 20.minutes.ago,
          limit: 5
        }, as: :json
      end

      audit_logs = AuditLog.where(user_id: request_user.id, auditable_type: auditable_type)
      expect(audit_logs.count).to be 5
      expect(audit_logs.map(&:auditable_id).to_set).to eq(records.map(&:id).to_set)
      expect(audit_logs.map(&:action).to_set).to eq(['fetch'].to_set)
    end
  end
end

RSpec.shared_examples 'a working sync controller that short circuits disabled apis' do
  describe 'if API is disabled' do
    let(:request_key) { model.to_s.underscore.pluralize }
    let(:payload) { Hash[request_key, (1..10).map { build_payload.call }] }

    before 'each' do
      set_authentication_headers
      expect(FeatureToggle).to receive(:enabled_for_regex?).with('MATCHING_SYNC_APIS', request_key).and_return(false)
    end

    it 'returns 200 for all POST calls' do
      post(:sync_from_user, params: payload)

      expect(response.status).to eq(403)
    end

    it 'does not create any entries in the database' do
      post(:sync_from_user, params: payload)

      expect(model.count).to eq(0)
    end
  end
end
