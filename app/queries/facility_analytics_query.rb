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
        .registered_patients
        .group('registration_user_id')
        .distinct('patients.id')
        .count

    return if @total_registered_patients.blank?

    @total_registered_patients
      .map { |user_id, count| [user_id, { :total_registered_patients => count }] }
      .to_h
  end

  def registered_patients_by_period
    @registered_patients_by_period ||=
      @facility
        .registered_patients
        .group('registration_user_id')
        .group_by_period(@period, :recorded_at)
        .distinct('patients.id')
        .count

    group_by_user_and_date(@registered_patients_by_period, :registered_patients_by_period)
  end

  def follow_up_patients_by_period
    @follow_up_patients_by_period ||=
      #
      # The DISTINCT ON is for when a patient visits a facility twice in a period and is seen by different users.
      # Without it, the visit is counted twice and the total increases in comparison to facility follow ups.
      #
      # The salient clause: we're DISTINCTing ON the BloodPressure.date_to_period_sql and the patient_id.
      #
      # However, we've turned this into a nested subquery using .from as a workaround for ActiveRecord's inability to
      # compose a COUNT with a DISTINCT ON – it ends up with garble like COUNT DISTINCT DISTINCT ON which is a
      # completely invalid query.
      #
      Patient
        .from(Patient
                .joins(:blood_pressures)
                .hypertension_follow_ups_by_period(@period, last: @prev_periods)
                .distinct(false) # this removes the distinct from hypertension_follow_ups so we can apply DISTINCT ON
                .group('bp_user_id',
                       'blood_pressures.patient_id',
                       BloodPressure.date_to_period_sql('blood_pressures.recorded_at', @period),
                       'blood_pressures.recorded_at',
                       'patients.deleted_at')
                .where(blood_pressures: { facility: @facility })
                .select(%Q(
                    DISTINCT ON (blood_pressures.patient_id,
                    #{BloodPressure.date_to_period_sql('blood_pressures.recorded_at', @period)})
                    blood_pressures.user_id AS bp_user_id,
                    patients.deleted_at))
                .select("blood_pressures.recorded_at AS bp_recorded_at")
                .order('blood_pressures.patient_id', 
                       Arel.sql(BloodPressure.date_to_period_sql('blood_pressures.recorded_at', @period)),
                       'blood_pressures.recorded_at'),
              'patients')
        .group('bp_user_id')
        .group_by_period(:month, 'bp_recorded_at')
        .count

    group_by_user_and_date(@follow_up_patients_by_period, :follow_up_patients_by_period)
  end

  def total_calls_made_by_period
    @total_calls_made_by_period ||=
      CallLog
        .result_completed
        .joins(%Q(INNER JOIN phone_number_authentications
                  ON phone_number_authentications.phone_number = call_logs.caller_phone_number))
        .joins(%Q(INNER JOIN facilities
                  ON facilities.id = phone_number_authentications.registration_facility_id))
        .joins(%Q(INNER JOIN user_authentications
                  ON user_authentications.authenticatable_id = phone_number_authentications.id))
        .where(phone_number_authentications: { registration_facility_id: @facility.id })
        .group('user_authentications.user_id::uuid')
        .group_by_period(@period, :end_time)
        .count

    group_by_user_and_date(@total_calls_made_by_period, :total_calls_made_by_period)
  end

  private

  def group_by_user_and_date(query_results, key)
    valid_dates = dates_for_periods(@period,
                                    @prev_periods,
                                    from_time: @from_time,
                                    include_current_period: @include_current_period)

    query_results.map do |(user_id, date), value|
      { user_id => { key => { date.to_date => value }.slice(*valid_dates) } }
    end.inject(&:deep_merge)
  end
end


