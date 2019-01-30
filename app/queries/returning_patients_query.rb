class ReturningPatientsQuery
  attr_reader :facilities

  def initialize(facilities = Facility.none)
    @facilities = facilities
  end

  def call
    CountQuery.new(BloodPressure.where(facility: facilities))
      .distinct_count('patient_id', group_by_columns: 'facility_id')
  end
end