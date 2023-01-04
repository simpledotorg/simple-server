FactoryBot.define do
  factory :questionnaire_version do
    id { SecureRandom.uuid }
    questionnaire_type { "monthly_screening_reports" }
    dsl_version { 1 }
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
  end
end
