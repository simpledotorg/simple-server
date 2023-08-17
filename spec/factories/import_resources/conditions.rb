def build_condition_import_resource
  created_at = Faker::Time.between(from: 3.days.ago, to: 1.day.ago, format: :iso8601)
  updated_at = Faker::Time.between(from: 1.day.ago, to: Time.current, format: :iso8601)
  {
    resourceType: "Condition",
    meta: {lastUpdated: updated_at, createdAt: created_at},
    identifier: [{value: Faker::Alphanumeric.alphanumeric}],
    subject: {identifier: Faker::Alphanumeric.alphanumeric},
    code: {
      coding: 2.times.map do
        {system: "http://snomed.info/sct",
         code: %w[38341003 73211009].sample}
      end.uniq
    }
  }
end
