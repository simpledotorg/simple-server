FactoryBot.define do
  factory :appointment_reminder do
    id { SecureRandom.uuid }
    remind_on { Date.current + 3.days }
    status { "pending" }
    message { "notifications.set01.basic" }
    association :appointment, factory: :appointment
    association :patient, factory: :patient
    association :experiment, factory: :experiment
    association :reminder_template, factory: :reminder_template
  end
end
