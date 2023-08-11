def build_observation_import_resource(observation_type)
  created_at = Faker::Time.between(from: 3.days.ago, to: 1.day.ago, format: :iso8601)
  updated_at = Faker::Time.between(from: 1.day.ago, to: Time.current, format: :iso8601)
  resource = {
    resourceType: "Observation",
    meta: {
      lastUpdated: updated_at,
      createdAt: created_at
    },
    identifier: [{value: Faker::Alphanumeric.alphanumeric}],
    subject: {identifier: Faker::Alphanumeric.alphanumeric},
    performer: [{identifier: Faker::Alphanumeric.alphanumeric}],
    effectiveDateTime: Faker::Time.between(from: 5.years.ago, to: Time.current)
  }

  case observation_type
  when :blood_pressure
    resource.merge(
      code: {coding: [system: "http://loinc.org", code: "85354-9"]},
      component: [
        {code: {coding: [system: "http://loinc.org", code: "8480-6"]},
         valueQuantity: blood_pressure_value_quantity(:systolic)},
        {code: {coding: [system: "http://loinc.org", code: "8462-4"]},
         valueQuantity: blood_pressure_value_quantity(:diastolic)}
      ]
    )
  when :blood_sugar
    type_of_measure = %w[2339-0 87422-2 88365-2 4548-4].sample
    resource.merge(
      code: {coding: [system: "http://loinc.org", code: "2339-0"]},
      component: [
        {code: {coding: [system: "http://loinc.org",
                         code: type_of_measure]},
         valueQuantity: blood_sugar_value_quantity([:hba1c, :other].sample)}
      ]
    )
  else
    {}
  end
end

def blood_pressure_value_quantity(type)
  value = if type == :systolic
    Faker::Number.between(from: 90, to: 180)
  elsif type == :diastolic
    Faker::Number.between(from: 60, to: 100)
  end

  {value: value,
   unit: "mmHg",
   system: "http://unitsofmeasure.org",
   code: "mm[Hg]"}
end

def blood_sugar_value_quantity(type)
  case type
  when :hba1c
    {value: Faker::Number.between(from: 1, to: 10),
     unit: "%",
     system: "http://unitsofmeasure.org",
     code: "%"}
  else
    {value: Faker::Number.between(from: 100, to: 300),
     unit: "mg/dL",
     system: "http://unitsofmeasure.org",
     code: "mg/dL"}
  end
end
