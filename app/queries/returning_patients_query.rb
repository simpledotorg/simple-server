class ReturningPatientsQuery
  attr_reader :facilities

  def initialize(facilities = Facility.none, from_date:, to_date:)
    @facilities = facilities
    @from_date = from_date
    @to_date = to_date
  end

  def call
    CountQuery.new(relation)
      .distinct_count('patient_id', group_by_columns: 'facility_id')
  end

  private

  def relation
    BloodPressure.where(facility: facilities)
      .where('device_created_at > ?', @from_date)
      .where('device_created_at <= ?', @to_date)
  end
end