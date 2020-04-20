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
      dates_for_periods(@period,
                        @prev_periods,
                        from_time: @from_time,
                        include_current_period: @include_current_period).map do |date|


        Patient.from(Patient
                       .follow_ups(@period, date)
                       .where(blood_pressures: { facility: @facility })
                       .select('DISTINCT ON (blood_pressures.patient_id) patients.*')
                       .select('blood_pressures.user_id AS user_id')
                       .order('blood_pressures.patient_id', 'blood_pressures.recorded_at')
                       .joins(:blood_pressures),
                     'patients')
          .group('user_id')
          .count
          .map { |user_id, count| [[user_id, date], count] }
          .to_h
      end.inject(:merge)

    group_by_user_and_date(@follow_up_patients_by_period, :follow_up_patients_by_period)
  end

  def total_calls_made_by_period
    @total_calls_made_by_period ||=
      CallLog
        .result_completed
        .joins('INNER JOIN phone_number_authentications ON phone_number_authentications.phone_number = call_logs.caller_phone_number')
        .joins('INNER JOIN facilities ON facilities.id = phone_number_authentications.registration_facility_id')
        .joins('INNER JOIN user_authentications ON user_authentications.authenticatable_id = phone_number_authentications.id')
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
      { user_id => { key => { date => value }.slice(*valid_dates) } }
    end.inject(&:deep_merge)
  end
end
