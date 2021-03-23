FactoryBot.define do
  factory :appointment_reminder do
    id { SecureRandom.uuid }
    remind_on { Date.current + 3.days }
    status { "pending" }
    message { "Your appointment is in three days" }
    association :appointment, factory: :appointment
    association :patient, factory: :patient
    reminder_template { nil }
  end
end
