class NonReturningHypertensivePatientsDuringPeriodQuery
  attr_reader :patients

  def initialize(patients:)
    @patients = patients
  end

  def non_returning_since(before_time)
    patients
      .joins(:cached_latest_blood_pressure)
      .where('cached_latest_blood_pressures.device_created_at < ?', before_time)
      .where('cached_latest_blood_pressures.systolic >= ?', 140)
      .where('cached_latest_blood_pressures.diastolic >= ?', 90)
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
end