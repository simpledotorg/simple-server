FactoryBot.define do
  factory :treatment_group, class: Experimentation::TreatmentGroup do
    description { Faker::Lorem.unique.word }
    association :experiment, factory: :experiment
  end

  trait :with_template do
    reminder_templates { create_list(:reminder_template, 1) }
  end
end
