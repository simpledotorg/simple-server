FactoryBot.define do
  factory :reminder_template, class: Experimentation::ReminderTemplate do
    message { "Your appointment is in three days" }
    appointment_offset { -3 }
    association :treatment_bucket, factory: :treatment_bucket
  end
end
