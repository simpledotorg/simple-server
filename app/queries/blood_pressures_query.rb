class BloodPressuresQuery
  attr_reader :relation

  def initialize(relation = BloodPressure.all)
    @relation = relation
  end

  def for_facilities(facilities)
    relation.where(facility: facilities)
  end

  def for_facility_group(facility_group)
    relation.where(facility: facility_group.facilities)
  end
end