require "rails_helper"

RSpec.describe Api::V4::QuestionnaireResponsesController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:model) { QuestionnaireResponse }
  # let(:build_payload) { -> { build_blood_sugar_payload } }
  # let(:build_invalid_payload) { -> { build_invalid_blood_sugar_payload } }
  # let(:invalid_record) { build_invalid_payload.call }
  # let(:update_payload) { ->(blood_sugar) { updated_blood_sugar_payload(blood_sugar) } }
  # let(:number_of_schema_errors_in_invalid_payload) { 2 }

  before do
    @questionnaire_types = stub_questionnaire_types
  end

  def create_record(options = {})
    facility = options[:facility] || create(:facility, facility_group: request_facility_group)
    questionnaire = options[:questionnaire] || create(:questionnaire)
    create(:questionnaire_response, questionnaire: questionnaire, facility: facility)
  end

  def create_record_list(n, options = {})
    facility = options[:facility] || create(:facility, facility_group: request_facility_group)
    questionnaire = options[:questionnaire] || create(:questionnaire)

    create_list(:questionnaire_response, n, questionnaire: questionnaire, facility: facility)
  end

  it_behaves_like "a sync controller that authenticates user requests"
  it_behaves_like "a sync controller that audits the data access"

  describe "GET sync: send data from server to device;" do
    it_behaves_like "a working V3 sync controller sending records"
    it "sends records only for the current facility" do
    end

    it "resyncs records when a user changes facilities" do
    end

    it "syncs records for records in the request facility only" do
      #TODO: check if this spec does what is says
      request_2_facility = create(:facility, facility_group: request_facility_group)

      create_record_list(2, facility: request_facility, updated_at: 3.minutes.ago)
      create_record_list(2, facility: request_facility, updated_at: 5.minutes.ago)
      create_record_list(2, facility: request_2_facility, updated_at: 7.minutes.ago)
      create_record_list(2, facility: request_2_facility, updated_at: 10.minutes.ago)

      # GET request 1
      set_authentication_headers
      get :sync_to_user, params: {limit: 4}
      response_1_body = JSON(response.body)

      record_ids = response_1_body["questionnaire_responses"].map { |r| r["id"] }
      records = model.where(id: record_ids)
      expect(records.count).to eq 4
      expect(records.map(&:facility).to_set).to eq Set[request_facility]

      reset_controller

      # GET request 2
      get :sync_to_user, params: {limit: 4, process_token: response_1_body["process_token"]}
      response_2_body = JSON(response.body)

      record_ids = response_2_body["questionnaire_responses"].map { |r| r["id"] }
      records = model.where(id: record_ids)
      expect(records.count).to eq 4
      expect(records.map(&:facility).to_set).to eq Set[request_facility, request_2_facility]
    end
  end
end
