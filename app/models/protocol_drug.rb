class ProtocolDrug < ApplicationRecord
  belongs_to :protocol
  has_many :drug_stocks

  before_create :assign_id

  validates :name, presence: true
  validates :dosage, presence: true

  enum drug_category: {
    hypertension_ccb: "Hypertension: CCB",
    hypertension_arb: "Hypertension: ARB",
    hypertension_diuretic: "Hypertension: Diuretic",
    hypertension_ace: "Hypertension: ACE",
    hypertension_other: "Hypertension: Other",
    diabetes: "Diabetes",
    other: "Other"
  }.freeze

  def assign_id
    self.id = SecureRandom.uuid
  end

  def sort_key
    [name, dosage.to_f]
  end
end
