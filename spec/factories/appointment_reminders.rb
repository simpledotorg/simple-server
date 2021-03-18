FactoryBot.define do
  factory :appointment_reminder do
    id { SecureRandom.uuid }
    remind_on { Date.current + 3.days }
    status { "pending" }
    appointment
  end
end
