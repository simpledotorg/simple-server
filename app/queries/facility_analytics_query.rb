class FacilityAnalyticsQuery
  include DashboardHelper

  def initialize(facility, period = :month, prev_periods = 3, from_time = Time.current, include_current_period: false)
    @facility = facility
    @period = period
    @prev_periods = prev_periods
    @from_time = from_time
    @include_current_period = include_current_period
  end

  def total_registered_patients
    @total_registered_patients ||=
      @facility
        .registered_hypertension_patients
        .group("registration_user_id")
        .distinct("patients.id")
        .count

    return if @total_registered_patients.blank?

    @total_registered_patients
      .map { |user_id, count| [user_id, {total_registered_patients: count}] }
      .to_h
  end

  def registered_patients_by_period
    @registered_patients_by_period ||=
      @facility
        .registered_hypertension_patients
        .group("registration_user_id")
        .group_by_period(@period, :recorded_at)
        .distinct("patients.id")
        .count

    group_by_user_and_date(@registered_patients_by_period, :registered_patients_by_period)
  end

  private

  def group_by_user_and_date(query_results, key)
    valid_dates = dates_for_periods(@period,
      @prev_periods,
      from_time: @from_time,
      include_current_period: @include_current_period)

    query_results.map { |(user_id, date), value|
      {user_id => {key => {date.to_date => value}.slice(*valid_dates)}}
    }.inject(&:deep_merge)
  end
end
