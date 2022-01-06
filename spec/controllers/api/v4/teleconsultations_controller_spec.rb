# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V4::TeleconsultationsController, type: :controller do
  let(:request_user) { create(:user, teleconsultation_facilities: [create(:facility)]) }
  let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
  before :each do
    request.env["X_USER_ID"] = request_user.id
    request.env["X_FACILITY_ID"] = request_facility.id
    request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
  end

  let(:model) { Teleconsultation }

  let(:build_payload) { -> { build_teleconsultation_payload } }
  let(:build_invalid_payload) { -> { build_invalid_teleconsultation_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { ->(teleconsultation) { updated_teleconsultation_payload(teleconsultation) } }
  let(:number_of_schema_errors_in_invalid_payload) { 1 }

  def create_record(options = {})
    facility = create(:facility, facility_group: request_user.facility.facility_group)
    create(:teleconsultation, {facility: facility}.merge(options))
  end

  def create_record_list(n, options = {})
    facility = create(:facility, facility_group: request_user.facility.facility_group)
    create_list(:teleconsultation, n, {facility: facility}.merge(options))
  end

  describe "user api authentication" do
    let(:request_key) { model.to_s.underscore.pluralize }
    let(:empty_payload) { {request_key => []} }

    before :each do
      _request_user = create(:user)
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

  describe "creates an audit log for data synced from user" do
    before :each do
      set_authentication_headers
    end

    let(:auditable_type) { model.to_s }
    let(:request_key) { model.to_s.underscore.pluralize }
    let(:model_class_sym) { model.to_s.underscore.to_sym }

    let(:record) { build_payload.call }
    let(:payload) { {request_key => [record]} }

    it "creates an audit log for new data created by the user" do
      Timecop.freeze do
        expect(AuditLogger)
          .to receive(:info).with({user: request_user.id,
                                   auditable_type: auditable_type,
                                   auditable_id: record["id"],
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

  describe "POST sync: send data from device to server;" do
    it_behaves_like "a working sync controller creating records"

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
            record = Api::V4::TeleconsultationTransformer.from_request(record)

            db_record = model.find(record["id"])
            expect(db_record.attributes.except("requested_medical_officer_id").with_payload_keys.with_int_timestamps)
              .to eq(record.merge(medical_officer_id: request_user.id).with_payload_keys.with_int_timestamps)
          end
        end
      end
    end

    describe "creates new teleconsultations" do
      before :each do
        request.env["HTTP_X_USER_ID"] = request_user.id
        request.env["HTTP_X_FACILITY_ID"] = request_facility.id
        request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
      end

      it "creates new teleconsultations" do
        nurse = create(:user)
        teleconsultations = (1..3).map {
          build_teleconsultation_payload(build(:teleconsultation, requester: nurse))
        }

        post(:sync_from_user, params: {teleconsultations: teleconsultations}, as: :json)
        expect(Teleconsultation.count).to eq 3
        expect(nurse.requested_teleconsultations.count).to eq 3
        expect(response).to have_http_status(200)
      end

      context "request" do
        it "saves the request attributes" do
          teleconsultation = build_teleconsultation_payload
          teleconsultation["record"] = nil

          post(:sync_from_user, params: {teleconsultations: [teleconsultation]}, as: :json)

          db_teleconsultation = Teleconsultation.find(teleconsultation["id"])
          expect(db_teleconsultation.request.with_int_timestamps).to eq(teleconsultation["request"].with_int_timestamps)
        end

        context "when request user cannot teleconsult" do
          before do
            user = create(:user, registration_facility: request_facility, teleconsultation_facilities: [])
            request.env["HTTP_X_USER_ID"] = user.id
            request.env["HTTP_AUTHORIZATION"] = "Bearer #{user.access_token}"
          end

          it "saves the request attributes" do
            teleconsultation = build_teleconsultation_payload
            teleconsultation["record"] = nil

            post(:sync_from_user, params: {teleconsultations: [teleconsultation]}, as: :json)

            db_teleconsultation = Teleconsultation.find(teleconsultation["id"])
            expect(db_teleconsultation.request.with_int_timestamps).to eq(teleconsultation["request"].with_int_timestamps)
          end
        end
      end

      context "record" do
        context "when request user can teleconsult" do
          it "saves the record attributes" do
            teleconsultation = build_teleconsultation_payload
            teleconsultation["request"] = nil

            post(:sync_from_user, params: {teleconsultations: [teleconsultation]}, as: :json)

            db_teleconsultation = Teleconsultation.find(teleconsultation["id"])
            expect(db_teleconsultation.record.with_int_timestamps).to eq(teleconsultation["record"].with_int_timestamps)
          end
        end

        context "when request user cannot teleconsult" do
          before do
            user = create(:user, registration_facility: request_facility, teleconsultation_facilities: [])
            request.env["HTTP_X_USER_ID"] = user.id
            request.env["HTTP_AUTHORIZATION"] = "Bearer #{user.access_token}"
          end

          it "returns errors" do
            teleconsultation = build_teleconsultation_payload
            teleconsultation["request"] = nil

            post(:sync_from_user, params: {teleconsultations: [teleconsultation]}, as: :json)

            expect(JSON(response.body)).to include "errors"
          end

          it "does not create the teleconsultation" do
            teleconsultation = build_teleconsultation_payload
            teleconsultation["request"] = nil

            post(:sync_from_user, params: {teleconsultations: [teleconsultation]}, as: :json)

            db_teleconsultation = Teleconsultation.where(id: teleconsultation["id"])
            expect(db_teleconsultation).to be_empty
          end
        end
      end
    end
  end
end
