require "rails_helper"

describe Api::V4::QuestionnairesController, type: :controller do
  def make_process_token(params)
    Base64.encode64(params.merge({locale: I18n.locale}).to_json)
  end

  def discard_patient(record)
    record.update(deleted_at: Time.now())
  end

  before do
    @questionnaire_types = mock_questionnaire_types(15)
    @used_questionnaire_types = []
  end

  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:model) { Questionnaire }
  let(:dsl_version) { 2 }
  let(:custom_params) { {dsl_version: dsl_version} }

  def create_record(options = {})
    create(:questionnaire, **options)
  end

  def create_record_list(n, options = {})
    (@questionnaire_types.keys-@used_questionnaire_types).take(n).map do |questionnaire_type|
      @used_questionnaire_types << questionnaire_type
      create(:questionnaire, questionnaire_type: questionnaire_type, dsl_version: dsl_version, **options)
    end
  end

  describe "GET sync: send data from server to device;" do
    before :each do
      set_authentication_headers
    end

    it_behaves_like "a working V3 sync controller sending records"

    it "returns questionnaires only for given DSL Version" do
      version_1_questionnaire = create(:questionnaire, questionnaire_type: "monthly_screening_reports" , dsl_version: 1)
      version_2_questionnaire = create(:questionnaire, questionnaire_type: "monthly_screening_reports", dsl_version: 2)

      get :sync_to_user, params: {dsl_version: 1}
      expect(JSON(response.body)["questionnaires"].first["id"]).to eq version_1_questionnaire.id

      get :sync_to_user, params: {dsl_version: 2}
      expect(JSON(response.body)["questionnaires"].first["id"]).to eq version_2_questionnaire.id
    end

    it "returns 400 when DSL version isn't given" do
      get :sync_to_user
      expect(response.status).to eq 400
    end

    # Specs which are included in Shared specs & excluded here:
    # 1. Force-resync when resync-token is modified.
    # 2. When a resource is updated, it is included in next Sync response
    # 3. Discarded resources are included in Sync response
  end

  it_behaves_like "a sync controller that authenticates user requests: sync_to_user"
  it_behaves_like "a sync controller that audits the data access: sync_to_user"
end
