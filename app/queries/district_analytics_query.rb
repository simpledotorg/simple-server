class DistrictAnalyticsQuery
  def initialize(district_name:)
    @district_name = district_name
  end

  def registered_patients_by_month
    @registered_patients_by_month ||=
      Patient
        .joins(:registration_facility)
        .where(facilities: { district: @district_name })
        .group('facilities.id')
        .group_by_month(:device_created_at)
        .count

    group_by_facility(@registered_patients_by_month)
  end

  def follow_up_patients_by_month(months_prior: 3)
    @follow_up_patients_by_month ||=
      BloodPressure
        .select('facilities.id AS facility_id',
                "(DATE_TRUNC('month', (blood_pressures.device_created_at::timestamptz) AT TIME ZONE 'Etc/UTC')) AT TIME ZONE 'Etc/UTC'",
                'count(blood_pressures.id) AS blood_pressures_count')
        .left_outer_joins(:user)
        .left_outer_joins(:patient)
        .joins(:facility)
        .where(facilities: { district: @district_name })
        .group('facilities.id')
        .group_by_month('blood_pressures.device_created_at', last: months_prior)
        .where("patients.device_created_at < DATE_TRUNC('month', blood_pressures.device_created_at::timestamptz)")
        .order('facilities.id')
        .distinct
        .count('patients.id')

    group_by_facility(@follow_up_patients_by_month)
  end

  private

  def group_by_facility(query_results)
    query_results.map do |(facility_id, date), value|
      { facility_id => { date => value } }
    end.inject(&:deep_merge)
  end
end
