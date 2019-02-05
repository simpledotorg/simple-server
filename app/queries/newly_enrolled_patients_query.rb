class NewlyEnrolledPatientsQuery
  attr_reader :facilities, :from_date, :to_date

  def initialize(facilities = Facility.none, from_date: Date.new(0), to_date: Date.today)
    @facilities = facilities
    @from_date = from_date
    @to_date = to_date
  end

  def call(group_by_period: nil)
    CountQuery.new(relation)
      .distinct_count('id', group_by_columns: 'registration_facility_id', group_by_period: group_by_period)
  end

  private

  def relation
    Patient.where(registration_facility: facilities)
      .where('device_created_at > ?', @from_date)
      .where('device_created_at <= ?', @to_date)
  end
end