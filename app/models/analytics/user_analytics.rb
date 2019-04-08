class Analytics::UserAnalytics
  attr_reader :user, :facility, :from_time, :to_time

  def initialize(user, facility, from_time: 12.weeks.ago, to_time: Time.now)
    @user = user
    @facility = facility
    @from_time = from_time.at_beginning_of_week
    @to_time = to_time.at_beginning_of_week
  end

  def registered_patients_count
    user.registered_patients
      .where(registration_facility: facility)
      .where(device_created_at: from_time..to_time)
      .count
  end

  def blood_pressures_recorded_per_week
    user.blood_pressures
      .where(facility: facility)
      .group_by_week(:device_created_at, range: from_time..to_time)
      .count
  end

  def blood_pressures_recorded_per_week_at_facility
    user.blood_pressures
      .where(facility: facility)
      .group_by_week(:device_created_at, range: from_time..to_time)
      .count
  end

  def calls_made_by_user_at_facility
    Communication
      .where(user: user, appointment: facility.appointments)
      .where(device_created_at: from_time..to_time)
      .count
  end

  def returning_patients_count_at_facility
    BloodPressure.where(user: user)
      .where(facility: facility)
      .where(device_created_at: from_time..to_time)
      .distinct
      .count(:patient_id)
  end
end