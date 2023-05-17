require "rails_helper"

describe Api::V4::QuestionnairesController, type: :controller do
  def make_process_token(params)
    Base64.encode64({locale: I18n.locale}.merge(params).to_json)
  end

  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:model) { Questionnaire }
  let(:dsl_version) { "1" }

  before do
    @questionnaire_types = stub_questionnaire_types
  end

  def create_record(options = {})
    create(:questionnaire, **options)
  end

  def create_record_list(n, options = {})
    @used_questionnaire_types ||= []
    (@questionnaire_types - @used_questionnaire_types).take(n).map do |questionnaire_type|
      @used_questionnaire_types << questionnaire_type
      create(:questionnaire, :active, questionnaire_type: questionnaire_type, dsl_version: dsl_version, **options)
    end
  end

  describe "GET sync: send data from server to device;" do
    before :each do
      set_authentication_headers
    end

    context "a working sync controller sending records" do
      before :each do
        Timecop.travel(15.minutes.ago) do
          create_record_list(5)
        end
        Timecop.travel(14.minutes.ago) do
          create_record_list(5)
        end
      end

      let(:response_key) { model.to_s.underscore.pluralize }
      it "Returns records from the beginning of time, when process_token is not set" do
        get :sync_to_user, params: {dsl_version: dsl_version}

        response_body = JSON(response.body)
        expect(response_body[response_key].count).to eq model.count
        expect(response_body[response_key].map { |record| record["id"] }.to_set)
          .to eq(model.all.map(&:id).to_set)
      end

      it "Returns new records added since last sync" do
        expected_records = create_record_list(5, updated_at: 5.minutes.ago)
        get :sync_to_user, params: {
          process_token: make_process_token(current_facility_processed_since: 10.minutes.ago),
          dsl_version: dsl_version
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
          process_token: make_process_token(current_facility_processed_since: sync_time),
          dsl_version: dsl_version
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
            limit: 2,
            dsl_version: dsl_version
          }
          response_body = JSON(response.body)
          expect(response_body[response_key].count).to eq 2
        end

        it "Returns all the records on server over multiple small batches" do
          get :sync_to_user, params: {
            process_token: make_process_token(current_facility_processed_since: 20.minutes.ago),
            limit: 7,
            dsl_version: dsl_version
          }

          response_1 = JSON(response.body)

          reset_controller

          get :sync_to_user, params: {
            process_token: response_1["process_token"],
            limit: 8,
            dsl_version: dsl_version
          }
          response_2 = JSON(response.body)

          received_records = response_1[response_key].concat(response_2[response_key]).to_set
          expect(received_records.count).to eq model.count

          expect(received_records.map { |record| record["id"] }.to_set)
            .to eq(model.all.map(&:id).to_set)
        end
      end

      it "Returns discarded records" do
        expected_records = create_record_list(5, updated_at: 5.minutes.ago)
        discard_record = expected_records.first
        discard_record.discard

        get :sync_to_user, params: {dsl_version: dsl_version}

        response_body = JSON(response.body)
        expect(response_body[response_key].count).to eq 15

        expect(response_body[response_key].map { |record| record["id"] })
          .to include(discard_record.id)
      end
    end

    it "returns questionnaires with the same major dsl_version uptil given minor version" do
      allow_any_instance_of(Questionnaire).to receive(:validate_layout)

      questionnaire_1 = create(:questionnaire, :active, questionnaire_type: @questionnaire_types.first, dsl_version: "1")
      create(:questionnaire, questionnaire_type: @questionnaire_types.second, dsl_version: "1.1") # Inactive questionnaire
      questionnaire_11 = create(:questionnaire, :active, questionnaire_type: @questionnaire_types.second, dsl_version: "1.1")

      create(:questionnaire, :active, questionnaire_type: @questionnaire_types.third, dsl_version: "1.2") # Higher DSL version
      questionnaire_2 = create(:questionnaire, :active, questionnaire_type: @questionnaire_types.first, dsl_version: "2.0")

      # For clients supporting DSL version "1.1", return all questionnaires from 1 to 1.1.
      get :sync_to_user, params: {dsl_version: "1.1"}
      expect(JSON(response.body)["questionnaires"].pluck("id")).to match_array([questionnaire_1.id, questionnaire_11.id])

      get :sync_to_user, params: {dsl_version: "2.1"}
      expect(JSON(response.body)["questionnaires"].pluck("id")).to match_array(questionnaire_2.id)
    end

    it "de-duplicates multiple questionnaires of same type by choosing latest DSL version" do
      allow_any_instance_of(Questionnaire).to receive(:validate_layout)

      create(:questionnaire, :active, questionnaire_type: "monthly_screening_reports", dsl_version: "1.0")
      create(:questionnaire, :active, questionnaire_type: "monthly_screening_reports", dsl_version: "1.1")
      questionnaire = create(:questionnaire, :active, questionnaire_type: "monthly_screening_reports", dsl_version: "1.2")
      create(:questionnaire, :active, questionnaire_type: "monthly_screening_reports", dsl_version: "1.3")

      get :sync_to_user, params: {dsl_version: "1.2"}
      expect(JSON(response.body)["questionnaires"].first["id"]).to eq questionnaire.id
    end

    it "returns only one questionnaire per questionnaire_type" do
      _inactive_questionnaire = create(:questionnaire, questionnaire_type: "monthly_screening_reports", dsl_version: "1")
      active_questionnaire = create(:questionnaire, :active, questionnaire_type: "monthly_screening_reports", dsl_version: "1")

      get :sync_to_user, params: {dsl_version: "1"}
      expect(JSON(response.body)["questionnaires"].pluck("id")).to contain_exactly active_questionnaire.id
    end

    it "returns 400 when DSL version isn't given" do
      get :sync_to_user
      expect(response.status).to eq 400
    end
  end

  context "a sync controller that authenticates user requests: sync_to_user" do
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
      request.env["HTTP_X_USER_ID"] = "invalid user id"
      request.env["HTTP_AUTHORIZATION"] = "invalid access token"
      get :sync_to_user, params: empty_payload

      expect(response.status).to eq(401)
    end
  end

  context "a sync controller that audits the data access: sync_to_user" do
    include ActiveJob::TestHelper

    before :each do
      set_authentication_headers
    end

    let(:auditable_type) { model.to_s }
    let(:request_key) { model.to_s.underscore.pluralize }
    let(:model_class_sym) { model.to_s.underscore.to_sym }

    it "creates an audit log for data fetched by the user" do
      records = create_record_list(5)
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
            limit: 5,
            dsl_version: dsl_version
          }, as: :json
        end
      end
    end
  end
end
