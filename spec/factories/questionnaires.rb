FactoryBot.define do
  factory :questionnaire do
    id { SecureRandom.uuid }
    questionnaire_type { "monthly_screening_reports" }
    dsl_version { 1 }
    is_active { false }
    layout { Questionnaire.default_layout }

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
