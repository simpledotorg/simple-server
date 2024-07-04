def build_medication_request_import_resource
  created_at = Faker::Time.between(from: 3.days.ago, to: 1.day.ago, format: :iso8601)
  updated_at = Faker::Time.between(from: 1.day.ago, to: Time.current, format: :iso8601)
  contained_medication = {
    resourceType: "Medication",
    id: Faker::Alphanumeric.alphanumeric,
    status: %w[active inactive entered-in-error].sample,
    code: {
      coding: [{system: "http://www.nlm.nih.gov/research/umls/rxnorm",
                code: Faker::Alphanumeric.alphanumeric,
                display: Faker::Dessert.topping}]
    }
  }

  medication_unit = %w[mg ml g].sample
  {
    contained: [contained_medication],
    resourceType: "MedicationRequest",
    meta: {lastUpdated: updated_at, createdAt: created_at},
    identifier: [{value: Faker::Alphanumeric.alphanumeric}],
    subject: {identifier: Faker::Alphanumeric.alphanumeric},
    performer: {identifier: Faker::Alphanumeric.alphanumeric},
    medicationReference: {reference: "##{contained_medication[:id]}"},
    dispenseRequest: {
      expectedSupplyDuration: {
        value: Faker::Number.between(from: 1, to: 50),
        unit: "days",
        system: "http://unitsofmeasure.org",
        code: "d"
      }
    },
    dosageInstruction: [{
      timing: {code: %w[QD BID TID QID].sample},
      doseAndRate: [{doseQuantity: {value: Faker::Number.between(from: 1, to: 10),
                                    unit: medication_unit,
                                    system: "http://unitsofmeasure.org",
                                    code: medication_unit}}],
      text: Faker::Quote.yoda
    }]
  }
end
