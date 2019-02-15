class Analytics::UserAnalytics
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def registered_patients_count
    user.registered_patients.count
  end

  def blood_pressures_recorded_per_week
    user.blood_pressures
      .group_by_week(:device_created_at, last: 12)
      .count
  end

  def blood_pressures_recorded_per_week_at_facility(facility)
    user.blood_pressures
      .where(facility: facility)
      .group_by_week(:device_created_at, last: 12)
      .count
  end

  def calls_made_by_user_at_facility(facility)
    Communication.where(user: user, appointment: facility.appointments).count
  end

  def returning_patients_count_at_facility(facility)
    BloodPressure.where(user: user)
      .where(facility: facility)
      .distinct
      .count(:patient_id)
  end
end