class EstimatedPopulation < ApplicationRecord
  has_one :region

  validates :population, presence: true
  validates :region_id, presence: true
  validates :diagnosis, presence: true

  enum diagnosis: { hypertension: "HTN", diabetes: "DM" }

  validate :can_only_be_set_for_district_or_state

  def check_if_population_is_set_for_region
    if Region.find(self.region_id).estimated_population.population
      population = EstimatedPopulation.find_by(region_id: self.region_id)
      population.population = self.population
      puts "TEST"
      false
    end
  end

  def can_only_be_set_for_district_or_state
    region_type = Region.find(self.region_id).region_type
    unless region_type === "district" || region_type === "state"
      errors.add(:region, "can only set population for a district or a state")
    end
  end
end