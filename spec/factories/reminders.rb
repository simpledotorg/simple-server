FactoryBot.define do
  factory :reminder do
    id { SecureRandom.uuid }
    remind_on { Date.current + 3.days }
    status { "pending" }
    message { "Your appointment is in three days" }
    association :appointment, factory: :appointment
    association :patient, factory: :patient
    association :experiment, factory: :experiment
    association :reminder_template, factory: :reminder_template
  end
end
