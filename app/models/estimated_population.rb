class EstimatedPopulation < ApplicationRecord
  belongs_to :region

  validates :population, presence: true
  validates :region_id, presence: true
  validates :diagnosis, presence: true

  enum diagnosis: { hypertension: "HTN", diabetes: "DM" }

  validate :can_only_be_set_for_district_or_state
  after_save :sum_state_level

  def can_only_be_set_for_district_or_state
    unless region.region_type === "state" || region.region_type === "district"
      errors.add(:region, "region type can only be district or state")
    end
  end

  def sum_state_level
    puts "TEST"
  end
end