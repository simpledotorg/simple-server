require "rails_helper"

describe Api::V4::QuestionnairesController, type: :controller do
  def make_process_token(params)
    Base64.encode64(params.merge({locale: I18n.locale}).to_json)
  end

  def discard_patient(record)
    record.update(deleted_at: Time.now())
  end

  def mock_questionnaire_types(n)
    new_types = (1..n).to_h { |i| ["type_#{i}".to_sym, "type_#{i}"] }

    questionnaire_types = Questionnaire.questionnaire_types.merge(new_types)
    allow(ActiveRecord::Enum::EnumType).to receive(:new).and_call_original
    allow(ActiveRecord::Enum::EnumType).to receive(:new).with("questionnaire_type", any_args).and_return(
      ActiveRecord::Enum::EnumType.new(
            "questionnaire_type",
            questionnaire_types,
            ActiveModel::Type::String.new)
    )

    questionnaire_types
  end

  before do
    @questionnaire_types = mock_questionnaire_types(15)
    @used_questionnaire_types = []
  end

  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:model) { Questionnaire }
  let(:custom_params) { {dsl_version: 2} }

  def create_record(options = {})
    create(:questionnaire, **options)
  end

  def create_record_list(n, options = {})
    (@questionnaire_types.keys-@used_questionnaire_types).take(n).map do |questionnaire_type|
      @used_questionnaire_types << questionnaire_type
      create(:questionnaire, questionnaire_type: questionnaire_type, dsl_version: custom_params[:dsl_version], **options)
    end
  end

  describe "GET sync: send data from server to device;" do
    it_behaves_like "a working V3 sync controller sending records"

    it "returns questionnaires only for given DSL Version" do
      #   Create questionnaire for 2 dsl_versions & expect only 1
    end

    it

    it "returns 400 when DSL version isn't given" do

    end

    it "does a force-resync when mismatch between locale in header and process token" do

    end

    # Specs which are included in Shared specs & excluded here:
    # 1. Force-resync when resync-token is modified.
    # 2. When a resource is updated, it is included in next Sync response
    # 3. Discarded resources are included in Sync response
  end

  it_behaves_like "a sync controller that authenticates user requests: sync_to_user"
  it_behaves_like "a sync controller that audits the data access: sync_to_user"
end
