class Analytics::FacilityAnalytics
  attr_accessor :facility

  def initialize(facility, months_previous: 12)
    @facility = facility
    @from_date = Date.today.at_beginning_of_month
    @to_date = Date.today.at_end_of_month
    @months_previous = months_previous
  end

  def newly_enrolled_patients_per_month
    @newly_enrolled_patients_per_month ||=
      NewlyEnrolledPatientsQuery.new(facility)
        .call(group_by_period: { period: :month, column: :device_created_at, options: { last: @months_previous } })
        .map { |key, value| [key.second, value] }
        .to_h
  end

  def newly_enrolled_patients_this_month
    newly_enrolled_patients_per_month[Date.today.at_beginning_of_month]
  end

  def returning_patients_count_this_month
    @returning_patients_count_this_month ||=
      ReturningPatientsQuery.new(facility, from_date: @from_date, to_date: @to_date)
        .call[facility.id] || 0
  end

  def unique_patients_recorded_per_month
    @unique_patients_recorded_per_month ||=
      CountQuery.new(BloodPressure.where(facility: facility))
        .distinct_count('patient_id', group_by_period:
          { period: :month, column: :device_created_at, options: { last: @months_previous } })
  end

  def overdue_patients_count_per_month(months_previous)
    OverduePatientsQuery.new(facility)
      .call
      .group_by_period(:month, 'blood_pressures.device_created_at', last: months_previous)
      .count
  end

  def overdue_patients_count_this_month
    overdue_patients_count_per_month(@months_previous)[Date.today.at_beginning_of_month] || 0
  end
end