FactoryBot.define do
  factory :treatment_group, class: Experimentation::TreatmentGroup do
    description { Faker::Lorem.unique.word }
    association :experiment, factory: :experiment
  end

  trait :with_template do
    after(:create) do |treatment_group|
      create_list(:reminder_template, 1, treatment_group: treatment_group)
    end
  end
end
