class Analytics::FacilityAnalytics
  attr_reader :facility, :from_time, :to_time

  def initialize(facility, from_time: Time.new(0), to_time: Time.now, months_previous: 12)
    @facility = facility
    @from_time = from_time
    @to_time = to_time
    @months_previous = months_previous
  end

  def unique_patients_enrolled
    UniquePatientsEnrolledQuery.new(facilities: facility).call
  end

  def newly_enrolled_patients
    NewlyEnrolledPatientsQuery.new(facilities: facility, from_time: from_time, to_time: to_time).call
  end

  def newly_enrolled_patients_per_month
    Patient.where(registration_facility: facility)
      .group_by_month(:device_created_at, last: @months_previous)
      .count(:id)
  end

  def returning_patients
    PatientsReturningDuringPeriodQuery.new(
      facilities: facility,
      from_time: from_time,
      to_time: to_time
    ).call
  end

  def non_returning_hypertensive_patients
    NonReturningHypertensivePatientsDuringPeriodQuery.new(
      facilities: facility,
      before_time: from_time
    ).call
  end

  def non_returning_hypertensive_patients_per_month(number_of_months)
    non_returning_hypertensive_patients_per_month = {}
    number_of_months.times do |n|
      before_time = (to_time - n.months).at_beginning_of_month
      non_returning_hypertensive_patients_per_month[before_time] =
        NonReturningHypertensivePatientsDuringPeriodQuery.new(
          facilities: facility,
          before_time: before_time
        ).call.count || 0
    end
    non_returning_hypertensive_patients_per_month.sort.to_h
  end

  def control_rate
    ControlRateQuery.new(facilities: facility, from_time: from_time, to_time: to_time).call
  end

  def all_time_patients_count
    Patient.where(registration_facility: facility).count
  end

  def control_rate_per_month(months_previous)
    return @control_rate_per_month if @control_rate_per_month.present?
    @control_rate_per_month = {}
    months_previous.times do |n|
      from_date = (months_previous - n).months.ago.at_beginning_of_month
      to_date = (months_previous - n).months.ago.at_end_of_month
      @control_rate_per_month[from_date] =
        ControlRateQuery.new(
          facilities: facility,
          from_time: from_date,
          to_time: to_date).call || 0
    end
    @control_rate_per_month
  end

  def blood_pressures_recorded_per_week
    facility.blood_pressures
      .where.not(user: nil)
      .group_by_week(:device_created_at, last: 12)
      .count
  end

  def unique_patients_recorded_per_month
    BloodPressure.where(facility: facility)
      .group_by_month(:device_created_at, last: @months_previous)
      .distinct
      .count(:patient_id)
  end
end
