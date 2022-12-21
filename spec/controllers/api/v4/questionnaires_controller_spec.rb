require "rails_helper"

describe Api::V4::QuestionnairesController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:model) { Questionnaire }
  let(:custom_params) { {dsl_version: 1} }

  def mock_questionnaire_types(n)
    id = SecureRandom.uuid
    type = "type_#{id[0..8]}"
    new_types = (1..n).to_h { |index| [type.to_sym, type] }

    questionnaire_types = Questionnaire.questionnaire_types.merge(new_types)
    allow(ActiveRecord::Enum::EnumType).to(
      receive(:new)
        .with("questionnaire_type", any_args)
        .and_return(
          ActiveRecord::Enum::EnumType.new(
            "questionnaire_type",
            questionnaire_types,
            ActiveModel::Type::String.new
          )
        )
    )

    questionnaire_types
  end

  def create_record(options = {})
    create(:questionnaire, **options)
  end

  def create_record_list(n, options = {})
    create_list(:questionnaire, n, questionnaire_type: "monthly_screening_reports", **options)
  end

  # describe "GET sync: send data from server to device;" do
  #   it_behaves_like "a working V3 sync controller sending records"
  # end
  #

  # it_behaves_like "a sync controller that authenticates user requests: sync_to_user"
  it_behaves_like "a sync controller that audits the data access: sync_to_user"
end
