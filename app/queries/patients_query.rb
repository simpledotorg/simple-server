class PatientsQuery
  attr_reader :relation

  def initialize(relation = Patient.all)
    @relation = relation
  end

  def registered_at(facility_id)
    relation
      .where("registration_facility_id = '#{facility_id}'")
  end
end