FactoryBot.define do
  factory :communication do
    id { SecureRandom.uuid }
    appointment
    user
    communication_type { :manual_call }
    device_created_at { Time.now }
    device_updated_at { Time.now }

    trait(:missed_visit_sms_reminder) { communication_type { :missed_visit_sms_reminder } }
  end
end

def build_communication_payload(communication = FactoryBot.build(:communication))
  communication.attributes.with_payload_keys
end

def build_invalid_communication_payload
  build_communication_payload.merge(
    'communication_type' => nil,
  )
end

def updated_communication_payload(existing_communication)
  update_time = 10.days.from_now
  build_communication_payload(existing_communication).merge(
    'updated_at' => update_time,
  )
end
