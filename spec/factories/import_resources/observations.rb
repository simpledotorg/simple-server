def build_observation_import_resource(observation_type)
  created_at = Faker::Time.between(from: 3.days.ago, to: 1.day.ago, format: :iso8601)
  updated_at = Faker::Time.between(from: 1.day.ago, to: Time.current, format: :iso8601)
  {
    resourceType: "Observation",
    meta: {
      lastUpdated: updated_at,
      createdAt: created_at
    },
    identifier: [{value: Faker::Alphanumeric.alphanumeric}],
    subject: {identifier: Faker::Alphanumeric.alphanumeric},
    performer: [{identifier: Faker::Alphanumeric.alphanumeric}],
    code: {coding: [system: "http://loinc.org", code: "85354-9"]},
    component: [
      {code: {coding: [system: "http://loinc.org", code: "8480-6"]},
       valueQuantity: {value: Faker::Number.between(from: 90, to: 180)}},
      {code: {coding: [system: "http://loinc.org", code: "8462-4"]},
       valueQuantity: {value: Faker::Number.between(from: 60, to: 100)}}
    ],
    effectiveDateTime: Faker::Time.between(from: 5.years.ago, to: Time.current)
  }
end
