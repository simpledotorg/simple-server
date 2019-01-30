class NewlyEnrolledPatientsQuery
  attr_reader :facilities
  def initialize(facilities = Facility.none)
    @facilities = facilities
  end

  def call(group_by_period: nil)
    CountQuery.new(Patient.where(registration_facility: facilities))
      .distinct_count('id', group_by_columns: 'registration_facility_id', group_by_period: group_by_period)
  end
end