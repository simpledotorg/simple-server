FactoryBot.define do
  factory :questionnaire do
    id { SecureRandom.uuid }
    questionnaire_type { "monthly_screening_reports" }
    dsl_version { 1 }
    is_active { false }
    layout {
      {
        type: "group",
        view_type: "view_group",
        display_properties: {
          orientation: "vertical"
        },
        item: []
      }
    }

    trait :active do
      is_active { true }
    end
  end
end

def stub_questionnaire_types(number_of_types = 15)
  new_types = (1..number_of_types).to_h { |i| ["type_#{i}".to_sym, "type_#{i}"] }
  questionnaire_types = Questionnaire.questionnaire_types.merge(new_types)
  allow(ActiveRecord::Enum::EnumType).to receive(:new).and_call_original
  allow(ActiveRecord::Enum::EnumType).to receive(:new).with("questionnaire_type", any_args).and_return(
    ActiveRecord::Enum::EnumType.new(
      "questionnaire_type",
      questionnaire_types,
      ActiveModel::Type::String.new
    )
  )

  questionnaire_types.keys
end

def build_questionnaire_response_payload(questionnaire_response = FactoryBot.build(:questionnaire_response))
  Api::V3::Transformer.to_response(questionnaire_response).with_indifferent_access
end

def build_invalid_questionnaire_response_payload
  build_questionnaire_response_payload.merge("created_at" => nil)
end
