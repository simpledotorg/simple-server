class NonReturningHypertensivePatientsDuringPeriodQuery
  attr_reader :facilities

  def initialize(facilities:)
    @facilities = facilities
  end

  def non_returning_since(before_time)
    Patient.where(registration_facility: facilities)
      .includes(:latest_blood_pressures)
      .select { |patient| non_returning_patient?(patient, before_time) }
  end

  def count_per_month(number_of_months, before_time: Date.today)
    patients = Patient.where(registration_facility: facilities).includes(:latest_blood_pressures)

    non_returning_hypertensive_patients_per_month = []
    number_of_months.times do |n|
      before_time = (before_time - n.months).at_beginning_of_month
      count = patients.select { |patient| non_returning_patient?(patient, before_time) }.size
      non_returning_hypertensive_patients_per_month << [before_time, count]
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