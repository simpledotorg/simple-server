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
end