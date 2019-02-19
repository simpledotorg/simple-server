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
    Patient.where(registration_facility: facility)
      .where('device_created_at <= ?', from_time)
      .includes(:latest_blood_pressures)
      .select do |patient|
      latest_blood_pressure = patient.latest_blood_pressure
      (latest_blood_pressure.present? && latest_blood_pressure.device_created_at >= from_time && latest_blood_pressure.device_created_at < to_time)
    end
  end

  def non_returning_hypertensive_patients
    non_returning_hypertensive_patients_in_period(from_time)
  end

  def non_returning_hypertensive_patients_per_month(number_of_months)
    non_returning_hypertensive_patients_per_month = {}
    number_of_months.times do |n|
      before_time = (to_time - n.months).at_beginning_of_month
      non_returning_hypertensive_patients_per_month[before_time] = non_returning_hypertensive_patients_in_period(before_time).size || 0
    end
    non_returning_hypertensive_patients_per_month.sort.to_h
  end

  def hypertensive_patients_recorded_in_period(from_time, to_time)
    BloodPressure.hypertensive
      .where(facility: facility)
      .where("device_created_at >= ?", from_time)
      .where("device_created_at <= ?", to_time)
      .pluck(:patient_id)
      .uniq
  end

  def patients_under_control_in_period(patient_ids, from_time, to_time)
    Patient.where(id: patient_ids)
      .includes(:latest_blood_pressures)
      .select do |patient|
      latest_blood_pressure = patient.latest_blood_pressure
      (latest_blood_pressure.present? &&
        latest_blood_pressure.under_control? &&
        latest_blood_pressure.device_created_at >= from_time &&
        latest_blood_pressure.device_created_at < to_time)
    end
  end

  def control_rate_for_period(from_time, to_time)
    hypertensive_patients_ids = hypertensive_patients_recorded_in_period(from_time - 9.months, to_time - 9.months)

    numerator = patients_under_control_in_period(hypertensive_patients_ids, from_time, to_time).size
    denominator = hypertensive_patients_ids.count

    (numerator * 100.0 / denominator).round unless denominator == 0
  end

  def control_rate
    control_rate_for_period(from_time, to_time)
  end


  def all_time_patients_count
    Patient.where(registration_facility: facility).count
  end

  def control_rate_per_month(months_previous)
    return @control_rate_per_month if @control_rate_per_month.present?
    @control_rate_per_month = {}
    months_previous.times do |n|
      from_date = (months_previous - n).months.ago.at_beginning_of_month
      to_time = (months_previous - n).months.ago.at_end_of_month
      @control_rate_per_month[from_date] = control_rate_for_period(from_date, to_time) || 0
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

  private

  def non_returning_hypertensive_patients_in_period(before_time)
    Patient.where(registration_facility: facility)
      .includes(:latest_blood_pressures)
      .select do |patient|
      latest_blood_pressure = patient.latest_blood_pressure
      latest_blood_pressure.present? && latest_blood_pressure.hypertensive? && patient.latest_blood_pressure.device_created_at < before_time
    end
  end
end
