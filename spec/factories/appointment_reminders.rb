FactoryBot.define do
  factory :appointment_reminder do
    id { SecureRandom.uuid }
    remind_at { Time.current + 3.days }
    status { "pending" }
    patient
    experiment { Experiment.first }
    appointment
  end
end