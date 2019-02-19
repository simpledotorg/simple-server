class Analytics::FacilityGroupAnalytics
  attr_reader :facility_group, :days_previous, :months_previous, :from_time, :to_time

  def initialize(facility_group, from_time: Time.new(0), to_time: Time.now, days_previous: 7, months_previous: 12)
    @facility_group = facility_group
    @days_previous = days_previous
    @months_previous = months_previous
    @from_time = from_time
    @to_time = to_time
  end

  def unique_patients_enrolled
    UniquePatientsEnrolledQuery.new(facilities: facility_group.facilities).call
  end

  def newly_enrolled_patients
    NewlyEnrolledPatientsQuery.new(
      facilities: facility_group.facilities,
      from_time: from_time,
      to_time: to_time
    ).call
  end

  def returning_patients
    PatientsReturningDuringPeriodQuery.new(
      facilities: facility_group.facilities,
      from_time: from_time,
      to_time: to_time
    ).call
  end

  def non_returning_hypertensive_patients
    NonReturningHypertensivePatientsDuringPeriodQuery.new(
      facilities: facility_group.facilities,
      before_time: from_time
    ).call
  end

  def non_returning_hypertensive_patients_per_month(number_of_months)
    return @non_returning_hypertensive_patients_per_month if @non_returning_hypertensive_patients_per_month.present?
    @non_returning_hypertensive_patients_per_month = {}
    number_of_months.times do |n|
      before_time = (to_time - n.months).at_beginning_of_month
      @non_returning_hypertensive_patients_per_month[before_time] =
        NonReturningHypertensivePatientsDuringPeriodQuery.new(
          facilities: facility_group.facilities,
          before_time: before_time
        ).call.count || 0
    end
    @non_returning_hypertensive_patients_per_month.sort
  end

  def control_rate
    ControlRateQuery.new(
      facilities: facility_group.facilities,
      from_time: from_time,
      to_time: to_time
    ).call
  end

  def control_rate_per_month(months_previous)
    return @control_rate_per_month if @control_rate_per_month.present?
    @control_rate_per_month = {}
    months_previous.times do |n|
      from_date = (months_previous - n).months.ago.at_beginning_of_month
      to_time = (months_previous - n).months.ago.at_end_of_month
      @control_rate_per_month[from_date] =
        ControlRateQuery.new(
          facilities: facility_group.facilities,
          from_time: from_time,
          to_time: to_time
        ).call || 0
    end
    @control_rate_per_month
  end
end