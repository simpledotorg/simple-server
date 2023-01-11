FactoryBot.define do
  factory :questionnaire_response do
    id { SecureRandom.uuid }
    content { {} }
    device_created_at { Time.current }
    device_updated_at { Time.current }

    association :questionnaire, strategy: :create
    association :facility
    association :user
  end
end

def build_questionnaire_response_payload(questionnaire_response = FactoryBot.build(:questionnaire_response))
  Api::V4::QuestionnaireResponseTransformer.to_response(questionnaire_response).with_indifferent_access
end

def build_invalid_questionnaire_response_payload
  build_questionnaire_response_payload.merge("created_at" => nil)
end
