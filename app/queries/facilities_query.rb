class FacilitiesQuery
  attr_reader :relation

  def initialize(relation = Facility.all)
    @relation = relation
  end

  def distinct_patients(facility_id)
    with_patients
      .where("facilities.id = '#{facility_id}'")
      .distinct('patients.id')
  end

  private

  def with_patients
    relation.joins(:patients)
  end
end