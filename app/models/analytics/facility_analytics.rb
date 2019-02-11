class Analytics::FacilityAnalytics
  attr_accessor :facility

  def initialize(facility, months_previous: 12)
    @facility = facility
    @from_date = Date.today.at_beginning_of_month
    @to_date = Date.today.at_end_of_month
    @months_previous = months_previous
  end

  def newly_enrolled_patients_per_month
    Patient.where(registration_facility: facility)
      .group_by_month(:device_created_at, last: @months_previous)
      .count(:id)
  end

  def newly_enrolled_patients_this_month
    newly_enrolled_patients_per_month[Date.today.at_beginning_of_month]
  end

  def returning_patients_count_this_month
    BloodPressure.where(facility: facility)
      .where('device_created_at > ?', @from_date)
      .where('device_created_at <= ?', @to_date)
      .distinct
      .count(:patient_id)
  end

  def unique_patients_recorded_per_month
    BloodPressure.where(facility: facility)
      .group_by_month(:device_created_at, last: @months_previous)
      .distinct
      .count(:patient_id)
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

  def hypertensive_patients_in_cohort(since: Time.new(0), upto: Time.now.in_time_zone("New Delhi"))
    BloodPressure.hypertensive
      .where(facility: facility)
      .where("device_created_at >= ?", since)
      .where("device_created_at <= ?", upto)

  end

  def controlled_patients_for_facility(patient_ids)
    BloodPressure.select('distinct on (patient_id) *')
      .where(facility: facility)
      .where(patient: patient_ids)
      .order(:patient_id, created_at: :desc)
      .select { |blood_pressure| blood_pressure.under_control? }
      .map(&:patient)
  end

  def control_rate_for_this_month
    hypertensive_patients = hypertensive_patients_in_cohort(
      since: Date.today.at_beginning_of_month,
      upto: Date.today.at_end_of_month
    )

    numerator = controlled_patients_for_facility(hypertensive_patients.pluck(:id)).size
    denominator = hypertensive_patients.count

    numerator.to_f / denominator unless denominator == 0
  end
end
