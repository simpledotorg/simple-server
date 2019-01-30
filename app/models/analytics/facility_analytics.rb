class Analytics::FacilityAnalytics
  attr_accessor :facility

  def initialize(facility, months_previous: 12)
    @facility = facility
    @from_date = Date.today.at_beginning_of_month
    @to_date = Date.today.at_end_of_month
    @months_previous = months_previous
  end

  def newly_enrolled_patients_count
    @newly_enrolled_patients ||=
      NewlyEnrolledPatientsQuery.new(facility, from_date: @from_date, to_date: @to_date)
        .call[facility.id] || 0
  end

  def returning_patients_count
    @returning_patients ||=
      ReturningPatientsQuery.new(facility_group.facilities, from_date: @from_date, to_date: @to_date)
        .call[facility.id] || 0
  end

  def unique_patients_recorded_per_month
    @unique_patients_recorded_per_month ||=
      CountQuery.new(BloodPressure.where(facility: facility))
        .distinct_count('patient_id', group_by_period:
          { period: :month, column: :device_created_at, options: { last: @months_previous } })
  end

  def newly_enrolled_patients_per_month
    @newly_enrolled_patients_per_month ||=
      NewlyEnrolledPatientsQuery.new(facility, from_date: @from_date, to_date: @to_date)
        .call(group_by_period: { period: :month, column: :device_created_at, options: { last: @months_previous } })
        .map { |key, value| [key.second, value]}
        .to_h
  end
end