class EstimatedPopulation < ApplicationRecord
  belongs_to :region

  validates :population, presence: true
  validates :region_id, presence: true
  validates :diagnosis, presence: true

  enum diagnosis: { hypertension: "HTN", diabetes: "DM" }
end