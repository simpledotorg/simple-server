require "rails_helper"

class Questionnaire < ApplicationRecord
  enum questionnaire_type: {
    monthly_screening_reports: "monthly_screening_reports",
    type_1: "type_one",
    type_2: "type_two",
    type_3: "type_three"
  }
end

describe Api::V4::QuestionnairesController, type: :controller do
  let(:request_user) { create(:user) }
  let(:request_facility_group) { request_user.facility.facility_group }
  let(:request_facility) { create(:facility, facility_group: request_facility_group) }
  let(:model) { Questionnaire }

  def create_record_list(n, options={})
    puts(Questionnaire.questionnaire_types)
  end

  it_behaves_like "a sync controller that authenticates user requests: sync_to_user"
  it_behaves_like "a sync controller that audits the data access: sync_to_user"

end
