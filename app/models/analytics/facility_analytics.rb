class Analytics::FacilityAnalytics
  attr_accessor :facility

  def initialize(facility, months_previous: 12)
    @facility = facility
    @from_date = Date.today.at_beginning_of_month
    @to_date = Date.today.at_end_of_month
    @months_previous = months_previous
  end

  def all_time_patients_count
    Patient.where(registration_facility: facility).count
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
    overdue_patients_count_per_month(@months_previous)[@from_date] || 0
  end

  def hypertensive_patients_in_cohort(since: Time.new(0), upto: Time.now.in_time_zone("New Delhi"))
    BloodPressure.hypertensive
      .where(facility: facility)
      .where("device_created_at >= ?", since - 9.months)
      .where("device_created_at <= ?", upto - 9.months)

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
    control_rate_for_period(@from_date, @to_date)
  end

  def hypertensive_patients_in_cohort_this_month
    hypertensive_patients_in_cohort(since: @from_date, upto: @to_date)
  end

  def control_rate_for_period(from_date, to_date)
    hypertensive_patients = hypertensive_patients_in_cohort(
      since: from_date,
      upto: to_date
    )

    numerator = controlled_patients_for_facility(hypertensive_patients.pluck(:patient_id)).size
    denominator = hypertensive_patients.count

    (numerator * 100.0 / denominator).round unless denominator == 0
  end

  def control_rate_per_month(months_previous)
    return @control_rate_per_month if @control_rate_per_month.present?
    @control_rate_per_month = {}
    months_previous.times do |n|
      from_date = (months_previous - n).months.ago.at_beginning_of_month
      to_date = (months_previous - n).months.ago.at_end_of_month
      @control_rate_per_month[from_date] = control_rate_for_period(from_date, to_date) || 0
    end
    @control_rate_per_month
  end
end
