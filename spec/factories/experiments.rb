FactoryBot.define do
  factory :experiment, class: Experimentation::Experiment do
    name { "any unique string" }
    state { "active" }
    start_date {}
    end_date {}
  end
end
