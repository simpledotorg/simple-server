require "rails_helper"

RSpec.describe Api::V4::QuestionnaireResponsesController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:model) { QuestionnaireResponse }
  let(:build_payload) { -> { build_questionnaire_response_payload } }

  let(:update_payload) { ->(questionnaire_response) { updated_questionnaire_response_payload(questionnaire_response) } }

  let(:build_invalid_payload) { -> { build_invalid_questionnaire_response_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:number_of_schema_errors_in_invalid_payload) { 1 }

  before do
    @questionnaire_types = stub_questionnaire_types
  end

  def create_record(options = {})
    facility = options[:facility] || request_facility
    questionnaire = options[:questionnaire] || create(:questionnaire)
    create(:questionnaire_response, questionnaire: questionnaire, facility: facility)
  end

  def create_record_list(n, options = {})
    facility = options[:facility] || request_facility
    questionnaire = options[:questionnaire] || create(:questionnaire)

    create_list(:questionnaire_response, n, questionnaire: questionnaire, facility: facility)
  end

  it_behaves_like "a sync controller that authenticates user requests"
  it_behaves_like "a sync controller that audits the data access: sync_to_user"
  it_behaves_like "a working sync controller creating records"

  describe "a sync controller that audits the data access: sync_from_user" do
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
        record[:facility_id] = existing_record.facility_id
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
        record[:facility_id] = existing_record.facility_id
        record[:updated_at] = 3.days.ago
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
    end
  end

  describe "GET sync: send data from server to device;" do
    it "Returns records only for the current facility" do
      questionnaire_responses = create_record_list(3, facility: request_facility)
      other_facility = create(:facility, facility_group: request_facility_group)
      create_record_list(3, facility: other_facility)

      set_authentication_headers
      get :sync_to_user, params: {limit: 4}
      response_1_body = JSON(response.body)

      expect(response_1_body["questionnaire_responses"].pluck("id")).to match_array questionnaire_responses.pluck(:id)
    end

    it "Resyncs records for new facility when a user changes facilities" do
      create_record_list(3, facility: request_facility)
      other_facility = create(:facility, facility_group: request_facility_group)
      questionnaire_responses = create_record_list(3, facility: other_facility)

      set_authentication_headers
      get :sync_to_user, params: {limit: 4}
      response_1_body = JSON(response.body)
      process_token = response_1_body["process_token"]

      reset_controller

      request.env["HTTP_X_FACILITY_ID"] = other_facility.id
      get :sync_to_user, params: {limit: 4, process_token: process_token}
      response_2_body = JSON(response.body)

      expect(response_2_body["questionnaire_responses"].pluck("id")).to match_array questionnaire_responses.pluck(:id)
    end

    describe "a working V4 sync controller sending records" do
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
        get :sync_to_user, params: {
          process_token: make_process_token(
            current_facility_processed_since: 10.minutes.ago,
            current_facility_id: request_facility.id
          )
        }

        response_body = JSON(response.body)
        expect(response_body[response_key].count).to eq 5

        expect(response_body[response_key].map { |record| record["id"] }.to_set)
          .to eq(expected_records.map(&:id).to_set)

        response_process_token = parse_process_token(response_body)
        expect(response_process_token[:current_facility_processed_since].to_time.to_i)
          .to eq(expected_records.map(&:updated_at).max.to_i)
      end

      it "Returns an empty list when there is nothing to sync" do
        sync_time = 10.minutes.ago
        get :sync_to_user, params: {
          process_token: make_process_token(
            current_facility_processed_since: sync_time,
            current_facility_id: request_facility.id
          )
        }
        response_body = JSON(response.body)
        response_process_token = parse_process_token(response_body)
        expect(response_body[response_key].count).to eq 0
        expect(response_process_token[:current_facility_processed_since].to_time.to_i).to eq sync_time.to_i
      end

      describe "batching" do
        it "returns the number of records requested with limit" do
          get :sync_to_user, params: {
            process_token: make_process_token(current_facility_processed_since: 20.minutes.ago),
            limit: 2
          }
          response_body = JSON(response.body)
          expect(response_body[response_key].count).to eq 2
        end

        it "Returns all the records on server over multiple small batches" do
          get :sync_to_user, params: {
            process_token: make_process_token(current_facility_processed_since: 20.minutes.ago),
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
        discarded_record = expected_records.first
        discarded_record.discard

        get :sync_to_user

        response_body = JSON(response.body)
        expect(response_body[response_key].count).to eq 15

        expect(response_body[response_key].map { |record| record["id"] })
          .to include(discarded_record.id)
      end
    end
  end

  describe "a working sync controller updating records" do
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
            .to eq(record.to_json_and_back.except("user_id", "questionnaire_type").with_int_timestamps)
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

      it "returns errors for records failing model-level validations" do
        record = build_payload.call.merge(questionnaire_id: SecureRandom.uuid)
        invalid_payload = {request_key => [record]}
        post(:sync_from_user, params: invalid_payload, as: :json)

        response_errors = JSON(response.body)["errors"].first

        expect(response_errors).to be_present
        expect(response_errors["id"]).to eq(record["id"])
        expect(response_errors["questionnaire"]).to eq(["must exist"])
      end
    end
  end
end
