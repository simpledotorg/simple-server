class FacilitiesQuery
  attr_reader :relation

  def initialize(relation = Facility.all)
    @relation = relation
  end

  def patients_registered_per_week(facility_id, weeks)
    with_patients \
      .where("facilities.id = '#{facility_id}'") \
      .distinct('patients.id') \
      .group_by_week('patients.device_created_at', last: weeks) \
      .count
  end

  private

  def with_patients
    relation.joins(:patients)
  end
end