class EstimatedPopulation < ApplicationRecord
  has_one :region

  validates :population, presence: true
  validates :region_id, presence: true
  validates :diagnosis, presence: true

  enum diagnosis: { hypertension: "HTN", diabetes: "DM" }

  validate :can_only_be_set_for_district_or_state
  validate :update_state_population

  def can_only_be_set_for_district_or_state
    region_type = Region.find(self.region_id).region_type

    unless region_type === "district" || region_type === "state"
      errors.add(:region, "can only set population for a district or a state")
    end
  end

  def update_state_population
    region = Region.find(self.region_id)
    if region.region_type === "district"
      state = Region.find(region.parent.id)
      state_population = EstimatedPopulation.find_by(region_id: state.id)
      if state_population
        district_populations = self.population
        state.children.each do |district|
          unless district.id === self.region_id
            district_populations += EstimatedPopulation.find_by(region_id: district.id).population
          end
        end
        state_population.population = district_populations
      else
        EstimatedPopulation.create!(population: self.population, diagnosis: "HTN", region_id: state.id)
      end
    end
  end
end