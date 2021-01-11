class ProtocolDrug < ApplicationRecord
  belongs_to :protocol
  before_create :assign_id

  validates :name, presence: true
  validates :dosage, presence: true

  enum drug_category: {
    hypertension_diuretic: "Hypertension: Diuretic",
    hypertension_arb: "Hypertension: ARB",
    hypertension_ccb: "Hypertension: CCB",
    hypertension_other: "Hypertension: Other",
    diabetes: "Diabetes",
    other: "Other"
  }.freeze

  def assign_id
    self.id = SecureRandom.uuid
  end
end
