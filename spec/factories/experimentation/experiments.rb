FactoryBot.define do
  factory :experiment, class: Experimentation::Experiment do
    name { Faker::Lorem.unique.word }
    experiment_type { "current_patients" }
    start_time { Date.current }
    end_time { 1.week.from_now }
  end

  trait :with_treatment_group do
    treatment_groups { create_list(:treatment_group, 1) }
  end

  trait :with_treatment_group_and_template do
    treatment_groups { create_list(:treatment_group, 1, :with_template) }
  end

  trait :running do
    start_time { 1.week.ago }
    end_time { 1.week.from_now }
  end
end
