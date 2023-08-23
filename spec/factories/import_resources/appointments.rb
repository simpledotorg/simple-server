def build_appointment_import_resource
  created_at = Faker::Time.between(from: 3.days.ago, to: 1.day.ago, format: :iso8601)
  updated_at = Faker::Time.between(from: 1.day.ago, to: Time.current, format: :iso8601)
  {
    resourceType: "Appointment",
    meta: {
      lastUpdated: updated_at,
      createdAt: created_at
    },
    identifier: [
      {
        value: Faker::Alphanumeric.alphanumeric
      }
    ],
    status: %w[pending fulfilled cancelled].sample,
    start: Faker::Time.between(from: 5.years.ago, to: 30.days.from_now),
    appointmentOrganization: {identifier: Faker::Alphanumeric.alphanumeric},
    appointmentCreationOrganization: [nil, {identifier: Faker::Alphanumeric.alphanumeric}].sample,
    participant: [{actor: {identifier: Faker::Alphanumeric.alphanumeric}}]
  }
end
