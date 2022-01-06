# frozen_string_literal: true

FactoryBot.define do
  factory :protocol do
    id { SecureRandom.uuid }
    name { Faker::Address.state + " Protocol" }
    follow_up_days { rand(1..60) }

    trait :with_minimal_drugs do
      protocol_drugs {
        [build(:protocol_drug,
          name: "Amlodipine",
          dosage: "5 mg",
          rxnorm_code: "329528",
          stock_tracked: true,
          drug_category: "hypertension_ccb",
          protocol_id: id)]
      }
    end

    trait :with_tracked_drugs do
      protocol_drugs {
        [
          build(:protocol_drug,
            name: "Amlodipine",
            dosage: "5 mg",
            rxnorm_code: "329528",
            stock_tracked: true,
            drug_category: "hypertension_ccb",
            protocol_id: id),
          build(:protocol_drug,
            name: "Amlodipine",
            dosage: "10 mg",
            rxnorm_code: "329526",
            stock_tracked: true,
            drug_category: "hypertension_ccb",
            protocol_id: id),
          build(:protocol_drug,
            name: "Telmisartan",
            dosage: "40 mg",
            rxnorm_code: "316764",
            stock_tracked: true,
            drug_category: "hypertension_arb",
            protocol_id: id),
          build(:protocol_drug,
            name: "Telmisartan",
            dosage: "80 mg",
            rxnorm_code: "316765",
            stock_tracked: true,
            drug_category: "hypertension_arb",
            protocol_id: id),
          build(:protocol_drug,
            name: "Losartan",
            dosage: "50 mg",
            rxnorm_code: "979467",
            stock_tracked: true,
            drug_category: "hypertension_arb",
            protocol_id: id),
          build(:protocol_drug,
            name: "Hydrochlorothiazide",
            dosage: "25 mg",
            rxnorm_code: "316049",
            stock_tracked: true,
            drug_category: "hypertension_diuretic",
            protocol_id: id),
          build(:protocol_drug,
            name: "Chlorthalidone",
            dosage: "12.5 mg",
            rxnorm_code: "331132",
            stock_tracked: true,
            drug_category: "hypertension_diuretic",
            protocol_id: id)
        ]
      }
    end
  end
end
