FactoryBot.define do
  factory :experiment, class: Experimentation::Experiment do
    name { Faker::Lorem.unique.word }
    experiment_type { "current_patients" }
    start_time { Date.current }
    end_time { 1.week.from_now }
  end

  trait :with_treatment_group do
    after(:create) do |experiment|
      create_list(:treatment_group, 1, experiment: experiment)
    end
  end

  trait :with_treatment_group_and_template do
    after(:create) do |experiment|
      create_list(:treatment_group, 1, :with_template, experiment: experiment)
    end
  end

  trait :running do
    start_time { 1.week.ago }
    end_time { 1.week.from_now }
  end

  trait :upcoming do
    start_time { 1.week.from_now }
    end_time { 2.week.from_now }
  end
end
