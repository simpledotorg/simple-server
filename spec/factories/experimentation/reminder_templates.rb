# frozen_string_literal: true

FactoryBot.define do
  factory :reminder_template, class: Experimentation::ReminderTemplate do
    message { "Your appointment is in three days" }
    remind_on_in_days { -3 }
    association :treatment_group, factory: :treatment_group
  end
end
