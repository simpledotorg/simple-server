FactoryBot.define do
  factory :voice_call_detail do
    call_request_id { SecureRandom.uuid }
    status { "requested" }

    trait :with_communication do
      after(:create) do |detail|
        appointment = create(:appointment, scheduled_date: 10.days.ago)
        notification = create(:notification,
          subject: appointment,
          patient: appointment.patient,
          purpose: "overdue_voice_call",
          status: "sent")
        create(:communication,
          communication_type: "ai_voice_call",
          detailable: detail,
          notification: notification)
      end
    end
  end
end
