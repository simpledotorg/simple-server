# frozen_string_literal: true

require "rails_helper"

def set_authentication_headers
  request.env["HTTP_X_USER_ID"] = request_user.id
  request.env["HTTP_X_FACILITY_ID"] = request_facility.id if defined? request_facility
  request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
end

def make_process_token(params)
  Base64.encode64(params.to_json)
end

def parse_process_token(response_body)
  JSON.parse(Base64.decode64(response_body["process_token"])).with_indifferent_access
end

def discard_patient(record)
  record.instance_of?(Patient) ? record.discard_data : record.patient.discard_data
end

RSpec.shared_examples "a sync controller that authenticates user requests: sync_from_user" do
  describe "user api authentication" do
    let(:request_key) { model.to_s.underscore.pluralize }
    let(:empty_payload) { {request_key => []} }

    before :each do
      _request_user = FactoryBot.create(:user)
      set_authentication_headers
    end

    it "allows sync_from_user requests to the controller with valid user_id and access_token" do
      post :sync_from_user, params: empty_payload

      expect(response.status).not_to eq(401)
    end
    it "does not allow sync_from_user requests to the controller with invalid user_id and access_token" do
      request.env["X_USER_ID"] = "invalid user id"
      request.env["HTTP_AUTHORIZATION"] = "invalid access token"
      post :sync_from_user, params: empty_payload

      expect(response.status).to eq(401)
    end
  end
end

RSpec.shared_examples "a sync controller that authenticates user requests: sync_to_user" do
  describe "user api authentication" do
    let(:request_key) { model.to_s.underscore.pluralize }
    let(:empty_payload) { {request_key => []} }

    before :each do
      _request_user = FactoryBot.create(:user)
      set_authentication_headers
    end

    it "allows sync_to_user requests to the controller with valid user_id and access_token" do
      get :sync_to_user, params: empty_payload

      expect(response.status).not_to eq(401)
    end

    it "returns 403 for user which has been denied access" do
      request_user.update(sync_approval_status: :denied)
      get :sync_to_user, params: empty_payload

      expect(response.status).to eq(403)
    end

    it "returns 403 for users which have sync approval status set to requested" do
      request_user.update(sync_approval_status: :requested)
      get :sync_to_user, params: empty_payload

      expect(response.status).to eq(403)
    end

    it "sets user logged_in_at on successful authentication" do
      now = Time.current
      Timecop.freeze(now) do
        get :sync_to_user, params: empty_payload

        request_user.reload
        expect(request_user.logged_in_at.to_i).to eq(now.to_i)
      end
    end

    it "does not allow sync_to_user requests to the controller with invalid user_id and access_token" do
      request.env["X_USER_ID"] = "invalid user id"
      request.env["HTTP_AUTHORIZATION"] = "invalid access token"
      get :sync_to_user, params: empty_payload

      expect(response.status).to eq(401)
    end
  end
end

RSpec.shared_examples "a sync controller that authenticates user requests" do
  it_behaves_like "a sync controller that authenticates user requests: sync_from_user"
  it_behaves_like "a sync controller that authenticates user requests: sync_to_user"
end

RSpec.shared_examples "a working sync controller creating records" do
  let(:request_key) { model.to_s.underscore.pluralize }
  let(:empty_payload) { {request_key => []} }

  let(:new_records) { (1..10).map { build_payload.call } }
  let(:new_records_payload) { {request_key => new_records} }

  let(:invalid_payload) { {request_key => [invalid_record]} }

  let(:invalid_records_payload) { (1..5).map { build_invalid_payload.call } }
  let(:valid_records_payload) { (1..5).map { build_payload.call } }
  let(:partially_valid_payload) { {request_key => invalid_records_payload + valid_records_payload} }

  before :each do
    set_authentication_headers
  end

  describe "creates new records" do
    it "returns 400 when there are no records in the request" do
      post(:sync_from_user, params: empty_payload)
      expect(response.status).to eq 400
    end

    it "creates new records without any associations" do
      post(:sync_from_user, params: new_records_payload, as: :json)
      expect(model.count).to eq 10
      expect(response).to have_http_status(200)
    end

    it "returns errors for invalid records" do
      post(:sync_from_user, params: invalid_payload, as: :json)

      response_errors = JSON(response.body)["errors"].first

      expect(response_errors).to be_present
      expect(response_errors["schema"]).to be_present
      expect(response_errors["id"]).to be_present
      expect(response_errors["schema"].count).to eq number_of_schema_errors_in_invalid_payload
    end

    it "returns errors for some invalid records, and accepts others" do
      model_name = partially_valid_payload.keys.first.singularize.classify
      allow(Statsd.instance).to receive(:increment).with(anything)
      expect(Statsd.instance).to receive(:increment).with("merge.#{model_name}.schema_invalid").exactly(5).times
      post(:sync_from_user, params: partially_valid_payload, as: :json)

      response_errors = JSON(response.body)["errors"]
      expect(response_errors.count).to eq 5
      expect(response_errors.map { |error| error["id"] })
        .to match_array(invalid_records_payload.map { |record| record["id"] })

      expect(model.count).to eq 5
      expect(model.pluck(:id))
        .to match_array(valid_records_payload.map { |record| record["id"] })
    end
  end
end

RSpec.shared_examples "a working sync controller updating records" do
  let(:request_key) { model.to_s.underscore.pluralize }
  let(:existing_records) { create_record_list(10) }
  let(:updated_records) { existing_records.map(&update_payload) }
  let(:updated_payload) { {request_key => updated_records} }

  before :each do
    set_authentication_headers
  end

  describe "updates records" do
    it "with updated record attributes" do
      post :sync_from_user, params: updated_payload, as: :json

      updated_records.each do |record|
        db_record = model.find(record["id"])
        expect(db_record.attributes.to_json_and_back.except("user_id").with_payload_keys.with_int_timestamps)
          .to eq(record.to_json_and_back.except("user_id").with_int_timestamps)
      end
    end

    it "no-ops the discarded records" do
      existing_records.map(&:discard)
      post :sync_from_user, params: updated_payload, as: :json

      updated_records.each do |record|
        db_record = model.with_discarded.find(record["id"])

        expect(db_record).to be_discarded
        expect(db_record
                   .attributes
                   .to_json_and_back
                   .except("user_id")
                   .with_payload_keys.with_int_timestamps)
          .not_to eq(record
                           .to_json_and_back
                           .except("user_id")
                           .with_int_timestamps)
      end
    end

    it "updates deduped records if a record was merged" do
      deduped_record = create_record_list(1).first
      deleted_record = existing_records.first
      updated_record = updated_records.first

      DeduplicationLog.create!(
        record_type: deleted_record.class.to_s,
        deduped_record_id: deduped_record.id,
        deleted_record_id: deleted_record.id
      )

      post :sync_from_user, params: updated_payload, as: :json

      db_record = model.find(deduped_record["id"])
      expect(db_record.attributes.to_json_and_back.except("id", "user_id").with_payload_keys.with_int_timestamps)
        .to eq(updated_record.to_json_and_back.except("id", "user_id").with_int_timestamps)
    end
  end
end

RSpec.shared_examples "a working V3 sync controller sending records" do
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

  describe "GET sync: send data from server to device;" do
    let(:response_key) { model.to_s.underscore.pluralize }
    it "Returns records from the beginning of time, when process_token is not set" do
      get :sync_to_user

      response_body = JSON(response.body)
      expect(response_body[response_key].count).to eq model.count
      expect(response_body[response_key].map { |record| record["id"] }.to_set)
        .to eq(model.all.pluck(:id).to_set)
    end

    it "Returns new records added since last sync" do
      expected_records = create_record_list(5, updated_at: 5.minutes.ago)
      get :sync_to_user, params: {process_token: make_process_token(other_facilities_processed_since: 10.minutes.ago)}

      response_body = JSON(response.body)
      expect(response_body[response_key].count).to eq 5

      expect(response_body[response_key].map { |record| record["id"] }.to_set)
        .to eq(expected_records.map(&:id).to_set)

      response_process_token = parse_process_token(response_body)
      expect(response_process_token[:other_facilities_processed_since].to_time.to_i)
        .to eq(expected_records.map(&:updated_at).max.to_i)
    end

    it "Returns an empty list when there is nothing to sync" do
      sync_time = 10.minutes.ago
      get :sync_to_user, params: {process_token: make_process_token(other_facilities_processed_since: sync_time)}
      response_body = JSON(response.body)
      response_process_token = parse_process_token(response_body)
      expect(response_body[response_key].count).to eq 0
      expect(response_process_token[:other_facilities_processed_since].to_time.to_i).to eq sync_time.to_i
    end

    describe "batching" do
      it "returns the number of records requested with limit" do
        get :sync_to_user, params: {
          process_token: make_process_token(other_facilities_processed_since: 20.minutes.ago),
          limit: 2
        }
        response_body = JSON(response.body)
        expect(response_body[response_key].count).to eq 2
      end

      it "Returns all the records on server over multiple small batches" do
        get :sync_to_user, params: {
          process_token: make_process_token(other_facilities_processed_since: 20.minutes.ago),
          limit: 7
        }

        response_1 = JSON(response.body)

        reset_controller

        get :sync_to_user, params: {
          process_token: response_1["process_token"],
          limit: 8
        }
        response_2 = JSON(response.body)

        received_records = response_1[response_key].concat(response_2[response_key]).to_set
        expect(received_records.count).to eq model.count

        expect(received_records.map { |record| record["id"] }.to_set)
          .to eq(model.all.pluck(:id).to_set)
      end
    end

    it "Returns discarded records" do
      expected_records = create_record_list(5, updated_at: 5.minutes.ago)
      discard_record = expected_records.first
      discard_patient(discard_record)

      get :sync_to_user

      response_body = JSON(response.body)
      expect(response_body[response_key].count).to eq 15

      expect(response_body[response_key].map { |record| record["id"] })
        .to include(discard_record.id)
    end
  end
end

RSpec.shared_examples "a working sync controller that supports region level sync" do
  let!(:response_key) {
    model.to_s.underscore.pluralize
  }
  let!(:facility_in_same_block) {
    create(:facility, state: request_facility.state, block: request_facility.block, facility_group: request_facility_group)
  }

  let!(:facility_in_other_block) {
    create(:facility, block: "Other Block", facility_group: request_facility_group)
  }

  let!(:facility_in_other_group) {
    create(:facility, facility_group: create(:facility_group))
  }

  let!(:patient_in_request_facility) { create(:patient, :without_medical_history, registration_facility: request_facility) }
  let!(:patient_in_same_block) { create(:patient, :without_medical_history, registration_facility: facility_in_same_block) }
  let!(:patient_assigned_to_block) { create(:patient, :without_medical_history, assigned_facility: facility_in_same_block) }
  let!(:patient_with_appointment_in_block) {
    create(:patient, :without_medical_history)
      .yield_self { |patient| create(:appointment, patient: patient, facility: facility_in_same_block) }
      .yield_self { |appointment| appointment.patient }
  }
  let!(:patient_in_other_block) { create(:patient, :without_medical_history, registration_facility: facility_in_other_block) }
  let!(:patient_in_other_facility_group) { create(:patient, :without_medical_history, registration_facility: facility_in_other_group) }

  before { set_authentication_headers }

  context "region-level sync" do
    context "when X_SYNC_REGION_ID is blank (support for old apps)" do
      it "sends facility group records irrespective of process_token's sync_region_id" do
        facility_group_records = [
          *create_record_list(2, patient: patient_in_request_facility, facility: request_facility),
          *create_record_list(2, patient: patient_in_same_block, facility: facility_in_same_block),
          *create_record_list(2, patient: patient_in_other_block, facility: facility_in_other_block)
        ]

        other_facility_group_records =
          create_record_list(2, patient: patient_in_other_facility_group, facility: facility_in_other_group)

        process_token_sync_region_ids = [nil, request_facility.region.block_region.id, request_facility.facility_group_id]

        process_token_sync_region_ids.each do |process_token_sync_region_id|
          process_token = make_process_token(sync_region_id: process_token_sync_region_id)

          get :sync_to_user, params: {process_token: process_token}

          response_record_ids = JSON(response.body)[response_key].map { |r| r["id"] }
          expect(response_record_ids).to match_array facility_group_records.map(&:id)
          expect(other_facility_group_records).not_to include(*response_record_ids)
        end
      end
    end

    context "when X_SYNC_REGION_ID is current_facility_group_id" do
      before { request.env["HTTP_X_SYNC_REGION_ID"] = request_facility_group.id }

      context "when process_token's sync_region_id is empty" do
        it "syncs facility group records" do
          facility_group_records = [
            *create_record_list(2, patient: patient_in_request_facility, facility: request_facility),
            *create_record_list(2, patient: patient_in_same_block, facility: facility_in_same_block),
            *create_record_list(2, patient: patient_in_other_block, facility: facility_in_other_block)
          ]

          other_facility_group_records =
            create_record_list(2, patient: patient_in_other_facility_group, facility: facility_in_other_group)

          get :sync_to_user

          response_record_ids = JSON(response.body)[response_key].map { |r| r["id"] }
          expect(response_record_ids).to match_array facility_group_records.map(&:id)
          expect(other_facility_group_records).not_to include(*response_record_ids)
        end
      end

      context "when process_token's sync_region_id is current_facility_group_id (i.e. app starts syncing)" do
        it "syncs facility group records" do
          process_token = make_process_token(sync_region_id: request_facility_group.id)
          facility_group_records = [
            *create_record_list(2, patient: patient_in_request_facility, facility: request_facility),
            *create_record_list(2, patient: patient_in_same_block, facility: facility_in_same_block),
            *create_record_list(2, patient: patient_in_other_block, facility: facility_in_other_block)
          ]

          other_facility_group_records =
            create_record_list(2, patient: patient_in_other_facility_group, facility: facility_in_other_group)

          get :sync_to_user, params: {process_token: process_token}

          response_record_ids = JSON(response.body)[response_key].map { |r| r["id"] }
          expect(response_record_ids).to match_array facility_group_records.map(&:id)
          expect(other_facility_group_records).not_to include(*response_record_ids)
        end
      end

      context "when process_token is block_id (this can happen if we switch from block sync to FG sync)" do
        it "force resyncs facility_group records" do
          process_token = make_process_token(sync_region_id: request_facility.region.block_region.id,
            current_facility_processed_since: Time.current,
            other_facilities_processed_since: Time.current)
          Timecop.travel(15.minutes.ago) { create_record_list(5) }

          get :sync_to_user, params: {process_token: process_token}

          response_record_ids = JSON(response.body)[response_key].map { |r| r["id"] }
          expect(response_record_ids).to match_array model.pluck(:id)
        end
      end

      it "syncs facility group records when user is a teleconsult MO" do
        allow_any_instance_of(User).to receive(:can_teleconsult?).and_return true
        block_records = Timecop.travel(15.minutes.ago) {
          create_record_list(2, patient: patient_in_same_block, facility: facility_in_same_block)
        }
        non_block_records = Timecop.travel(15.minutes.ago) { create_record_list(2, facility: facility_in_other_block) }

        # 2 current facility records
        get :sync_to_user, params: {limit: 2}
        response_record_ids = JSON(response.body)[response_key].map { |r| r["id"] }
        reset_controller

        # 1 current facility record, 2 other facility records
        # The last record in the first request is repeated as the first record in the second request.
        # This happens because of the >= comparison in the updated_on_server_since method.
        get :sync_to_user, params: {process_token: JSON(response.body)["process_token"], limit: 3}
        response_record_ids += JSON(response.body)[response_key].map { |r| r["id"] }

        expect(response_record_ids.uniq).to match_array (block_records + non_block_records).map(&:id).uniq
      end
    end

    context "when X_SYNC_REGION_ID is block_id" do
      before { request.env["HTTP_X_SYNC_REGION_ID"] = request_facility.region.block_region.id }

      context "when process_token's sync_region_id is empty (i.e. app starts syncing)" do
        it "syncs data belonging to the patients in the block of user's facility" do
          block_records = [
            create_record(patient: patient_in_request_facility, facility: request_facility),
            create_record(patient: patient_in_same_block, facility: facility_in_same_block),
            create_record(patient: patient_assigned_to_block, facility: facility_in_same_block),
            create_record(patient: patient_with_appointment_in_block, facility: facility_in_same_block)
          ]

          non_block_records = [
            create_record(patient: patient_in_other_block, facility: facility_in_other_block),
            create_record(patient: patient_in_other_facility_group)
          ]

          get :sync_to_user

          response_record_ids = JSON(response.body)[response_key].map { |r| r["id"] }
          expect(response_record_ids).to match_array block_records.map(&:id)
          expect(non_block_records).not_to include(*response_record_ids)
        end
      end

      context "when process_token's sync_region_id is current_facility_group_id" do
        it "force resyncs block records" do
          process_token = make_process_token(sync_region_id: request_facility_group.id,
            current_facility_processed_since: Time.current,
            other_facilities_processed_since: Time.current)
          block_records = Timecop.travel(15.minutes.ago) {
            create_record_list(5, patient: patient_in_same_block, facility: facility_in_same_block)
          }
          non_block_records = Timecop.travel(15.minutes.ago) { create_record_list(2, facility: facility_in_other_block) }

          get :sync_to_user, params: {process_token: process_token}

          response_record_ids = JSON(response.body)[response_key].map { |r| r["id"] }
          expect(response_record_ids).to match_array block_records.map(&:id)
          expect(non_block_records).not_to include(*response_record_ids)
        end

        it "sync facility group records when user is a teleconsult MO" do
          allow_any_instance_of(User).to receive(:can_teleconsult?).and_return true
          block_records = Timecop.travel(15.minutes.ago) {
            create_record_list(2, patient: patient_in_same_block, facility: facility_in_same_block)
          }
          non_block_records = Timecop.travel(15.minutes.ago) { create_record_list(2, facility: facility_in_other_block) }

          # 2 current facility records
          get :sync_to_user, params: {limit: 2}
          response_record_ids = JSON(response.body)[response_key].map { |r| r["id"] }
          reset_controller

          # 1 current facility record, 2 other facility records
          # The last record in the first request is repeated as the first record in the second request.
          # This happens because of the >= comparison in the updated_on_server_since method.
          get :sync_to_user, params: {process_token: JSON(response.body)["process_token"], limit: 3}
          response_record_ids += JSON(response.body)[response_key].map { |r| r["id"] }

          expect(response_record_ids.uniq).to match_array (block_records + non_block_records).map(&:id).uniq
        end
      end

      context "when process_token's sync_region_id is block_id (when we switch from FG sync to block level sync)" do
        it "syncs data belonging to the patients in the block of user's facility" do
          process_token = make_process_token(sync_region_id: request_facility.region.block_region.id)

          block_records = [
            *create_record_list(2, patient: patient_in_request_facility, facility: request_facility),
            *create_record_list(2, patient: patient_in_same_block, facility: facility_in_same_block),
            *create_record_list(2, patient: patient_assigned_to_block, facility: facility_in_same_block),
            *create_record_list(2, patient: patient_with_appointment_in_block, facility: facility_in_same_block)
          ]

          non_block_records = [
            *create_record_list(2, patient: patient_in_other_block, facility: facility_in_other_block),
            *create_record_list(2, patient: patient_in_other_facility_group)
          ]

          get :sync_to_user, params: {process_token: process_token}

          response_record_ids = JSON(response.body)[response_key].map { |r| r["id"] }
          expect(response_record_ids).to match_array block_records.map(&:id)
          expect(non_block_records).not_to include(*response_record_ids)
        end
      end
    end
  end
end

RSpec.shared_examples "a sync controller that audits the data access: sync_from_user" do
  include ActiveJob::TestHelper

  before :each do
    set_authentication_headers
  end

  let(:auditable_type) { model.to_s }
  let(:request_key) { model.to_s.underscore.pluralize }
  let(:model_class_sym) { model.to_s.underscore.to_sym }

  describe "creates an audit log for data synced from user" do
    let(:record) { build_payload.call }
    let(:payload) { {request_key => [record]} }

    it "creates an audit log for new data created by the user" do
      Timecop.freeze do
        expect(AuditLogger)
          .to receive(:info).with({user: request_user.id,
                                   auditable_type: auditable_type,
                                   auditable_id: record[:id],
                                   action: "create",
                                   time: Time.current}.to_json)

        post :sync_from_user, params: payload, as: :json
      end
    end

    it "creates an audit log for data updated by the user" do
      existing_record = create_record
      record[:id] = existing_record.id
      payload[request_key] = [record]
      Timecop.freeze do
        expect(AuditLogger)
          .to receive(:info).with({user: request_user.id,
                                   auditable_type: auditable_type,
                                   auditable_id: record[:id],
                                   action: "update",
                                   time: Time.current}.to_json)

        post :sync_from_user, params: payload, as: :json
      end
    end

    it "creates an audit log for data touched by the user" do
      existing_record = create_record
      record[:id] = existing_record.id
      record[:updated_at] = 3.days.ago
      payload[request_key] = [record]
      Timecop.freeze do
        expect(AuditLogger)
          .to receive(:info).with({user: request_user.id,
                                   auditable_type: auditable_type,
                                   auditable_id: record[:id],
                                   action: "touch",
                                   time: Time.current}.to_json)

        post :sync_from_user, params: payload, as: :json
      end
    end
  end
end

RSpec.shared_examples "a sync controller that audits the data access: sync_to_user" do
  include ActiveJob::TestHelper

  before :each do
    set_authentication_headers
  end

  let(:auditable_type) { model.to_s }
  let(:request_key) { model.to_s.underscore.pluralize }
  let(:model_class_sym) { model.to_s.underscore.to_sym }

  describe "creates an audit log for data synced to user" do
    let!(:records) { create_record_list(5) }
    it "creates an audit log for data fetched by the user" do
      Timecop.freeze do
        Sidekiq::Testing.inline! do
          records.each do |record|
            expect(AuditLogger)
              .to receive(:info).with({user: request_user.id,
                                       auditable_type: auditable_type,
                                       auditable_id: record[:id],
                                       action: "fetch",
                                       time: Time.current}.to_json)
          end
          get :sync_to_user, params: {
            processed_since: 20.minutes.ago,
            limit: 5
          }, as: :json
        end
      end
    end
  end
end

RSpec.shared_examples "a sync controller that audits the data access" do
  it_behaves_like "a sync controller that audits the data access: sync_from_user"
  it_behaves_like "a sync controller that audits the data access: sync_to_user"
end
