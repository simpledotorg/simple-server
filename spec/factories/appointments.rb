FactoryBot.define do
  factory :appointment do
    id { SecureRandom.uuid }
    facility
    association :patient, strategy: :build
    date { 30.days.from_now }
    status { :scheduled }
    status_reason { :not_called_yet }
    device_created_at { Time.now }
    device_updated_at { Time.now }
  end
end

def build_appointment_payload(appointment = FactoryBot.build(:appointment))
  appointment.attributes.with_payload_keys
end

def build_invalid_appointment_payload
  build_appointment_payload.merge(
    'status' => nil,
    'date' => 'foo'
  )
end

def updated_appointment_payload(existing_appointment)
  update_time = 10.days.from_now
  updated_status = Appointment.statuses.keys
                          .reject { |action| action == existing_appointment.status.to_s}
                          .sample

  build_appointment_payload(existing_appointment).merge(
    'updated_at' => update_time,
    'status' => updated_status
  )
end