# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    id { SecureRandom.uuid }
    remind_on { Date.current + 3.days }
    status { "pending" }
    message { "notifications.set01.basic" }
    association :patient, factory: :patient
    purpose { "missed_visit_reminder" }
    subject { build(:appointment) }

    trait :with_experiment do
      association :experiment, factory: :experiment
    end
  end
end
