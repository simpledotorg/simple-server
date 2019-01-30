class Analytics::FacilityGroupGraphics
  attr_reader :facility_group

  def initialize(facility_group, months_previous: 12)
    @facility_group = facility_group
    @from_date = Date.today.at_beginning_of_month
    @to_date = Date.today.at_end_of_month
  end

  def newly_enrolled_patients
    @newly_enrolled_patients ||=
      NewlyEnrolledPatientsQuery.new(facility_group.facilities, from_date: @from_date, to_date: @to_date)
        .call
        .reduce(0) { |sum, hash| sum += hash.second }
  end

  def returning_patients
    @returning_patients ||=
      ReturningPatientsQuery.new(facility_group.facilities, from_date: @from_date, to_date: @to_date)
        .call
        .reduce(0) { |sum, hash| sum += hash.second }
  end

  def patients_who_missed_appointments

  end
end