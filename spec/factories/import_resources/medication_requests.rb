def build_medication_request_import_resource
  created_at = Faker::Time.between(from: 3.days.ago, to: 1.day.ago, format: :iso8601)
  updated_at = Faker::Time.between(from: 1.day.ago, to: Time.current, format: :iso8601)
  contained_medication = {
    resourceType: "Medication",
    id: Faker::Alphanumeric.alphanumeric,
    code: {
      coding: [{system: "http://www.nlm.nih.gov/research/umls/rxnorm",
                code: Faker::Alphanumeric.alphanumeric,
                name: Faker::Dessert.topping}]
    }
  }

  {
    contained: [contained_medication],
    resourceType: "MedicationRequest",
    meta: {lastUpdated: updated_at, createdAt: created_at},
    identifier: [{value: Faker::Alphanumeric.alphanumeric}],
    subject: {identifier: Faker::Alphanumeric.alphanumeric},
    performer: {identifier: Faker::Alphanumeric.alphanumeric},
    medicationReference: "##{contained_medication[:id]}",
    dispenseRequest: {
      expectedSupplyDuration: {
        value: Faker::Number.between(from: 1, to: 50),
        unit: "days",
        system: "http://unitsofmeasure.org",
        code: "d"
      }
    },
    dosageInstruction: [{
      timing: {code: %w[QD BID TID QID]},
      doseAndRate: [{doseQuantity: {value: Faker::Number.between(from: 1, to: 10),
                                    unit: "mg",
                                    system: "http://unitsofmeasure.org",
                                    code: "mg"}}],
      text: Faker::Quote.yoda
    }]
  }
end
