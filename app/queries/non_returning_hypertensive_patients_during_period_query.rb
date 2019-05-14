class NonReturningHypertensivePatientsDuringPeriodQuery
  attr_reader :patients

  def initialize(patients:)
    @patients = patients
  end

  def non_returning_since(before_time)
    patients
      .where('latest_blood_pressures.device_created_at < ?', before_time)
      .where('latest_blood_pressures.systolic >= ?', 140)
      .where('latest_blood_pressures.diastolic >= ?', 90)
  end

  def count_per_month(number_of_months, before_time: Date.today)
    non_returning_hypertensive_patients_per_month = []
    number_of_months.times do |n|
      time = (before_time - n.months).at_beginning_of_month
      count = non_returning_since(time).size || 0
      non_returning_hypertensive_patients_per_month << [time, count]
    end
    non_returning_hypertensive_patients_per_month.sort.to_h
  end

  private

  def non_returning_patient?(patient, before_time)
    latest_blood_pressure = patient.latest_blood_pressure

    latest_blood_pressure.present? &&
      latest_blood_pressure.hypertensive? &&
      latest_blood_pressure.device_created_at < before_time
  end

end