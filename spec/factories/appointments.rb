# frozen_string_literal: true

FactoryBot.define do
  factory :appointment do
    id { SecureRandom.uuid }
    facility
    creation_facility { facility }
    association :patient, strategy: :build
    scheduled_date { 30.days.from_now }
    status { :scheduled }
    cancel_reason { nil }
    device_created_at { Time.current }
    device_updated_at { Time.current }
    agreed_to_visit { nil }
    remind_on { nil }
    appointment_type { Appointment.appointment_types.keys.sample }
    user

    trait :overdue do
      scheduled_date { rand(30..90).days.ago }
      status { :scheduled }
    end
  end
end

def build_appointment_payload(appointment = FactoryBot.build(:appointment))
  appointment.attributes.with_payload_keys
end

def build_invalid_appointment_payload
  build_appointment_payload.merge(
    "status" => nil,
    "scheduled_date" => "foo"
  )
end

def updated_appointment_payload(existing_appointment)
  update_time = 10.days.from_now
  updated_status = Appointment.statuses.keys
    .reject { |action| action == existing_appointment.status.to_s }
    .reject { |action| action == "cancelled" }
    .sample

  build_appointment_payload(existing_appointment).merge(
    "updated_at" => update_time,
    "status" => updated_status
  )
end
