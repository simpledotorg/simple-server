FactoryBot.define do
  factory :experiment, class: "Experimentation::Experiment" do
    state { 'active' }
    start_date {}
    end_date {}
  end
end
