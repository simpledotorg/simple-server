class DistrictAnalyticsQuery
  def initialize(district_name:)
    @district_name = district_name
  end

  def by_facility
    data = total_registered_patients
             .deep_merge(follow_up_patients_by_month)
             .deep_merge(registered_patients_by_month)
    Facility.where(id: data.keys).map { |f| [f, data[f.id]] }.to_h
  end

  private

  TOTAL_REGISTERED_PATIENTS_ATTRS = %w(total_registered_patients)
  MONTHLY_REGISTERED_PATIENTS_ATTRS =
    %w(registered_patients_penultimate_month registered_patients_last_month registered_patients_current_month)
  MONTHLY_FOLLOW_UP_PATIENTS_ATTRS =
    %w(follow_up_penultimate_month follow_up_last_month follow_up_current_month)

  def total_registered_patients
    @total_registered_patients ||=
      Patient
        .joins('INNER JOIN facilities ON facilities.id = patients.registration_facility_id')
        .where('facilities.district = ?', @district_name)
        .group('facilities.name', 'facilities.id')
        .order('facilities.name')
        .pluck("facilities.id AS facility_id",
               "count(distinct(patients.id)) AS #{TOTAL_REGISTERED_PATIENTS_ATTRS.first}")

    group_by_facility(@total_registered_patients, TOTAL_REGISTERED_PATIENTS_ATTRS)
  end

  def registered_patients_by_month
    @registered_patients_by_month ||=
      Patient
        .joins('INNER JOIN facilities ON facilities.id = patients.registration_facility_id')
        .where('facilities.district = ?', @district_name)
        .group('facilities.name', 'facilities.id')
        .order('facilities.name')
        .pluck("facilities.id AS facility_id",
               %Q(sum(CASE
                         WHEN patients.device_created_at >= date_trunc('MONTH', now() - interval '2 months')::DATE
                         AND patients.device_created_at < date_trunc('MONTH', now() - interval '1 month')::DATE THEN 1
                         ELSE 0
                     END) AS #{MONTHLY_REGISTERED_PATIENTS_ATTRS.first}),
               %Q(sum(CASE
                         WHEN patients.device_created_at >= date_trunc('MONTH', now() - interval '1 month')::DATE
                         AND device_created_at < date_trunc('MONTH', now())::DATE THEN 1
                         ELSE 0
                     END) AS #{MONTHLY_REGISTERED_PATIENTS_ATTRS.second}),
               %Q(sum(CASE
                         WHEN patients.device_created_at >= date_trunc('MONTH', now())::DATE
                         AND patients.device_created_at  < date_trunc('MONTH', now() + interval '1 month')::DATE then 1
                         ELSE 0
                     END) AS #{MONTHLY_REGISTERED_PATIENTS_ATTRS.third}))

    group_by_facility(@registered_patients_by_month, MONTHLY_REGISTERED_PATIENTS_ATTRS)
  end

  def follow_up_patients_by_month
    @follow_up_patients_by_month ||=
      BloodPressure
        .joins('LEFT OUTER JOIN users ON blood_pressures.user_id = users.id')
        .joins('LEFT OUTER JOIN patients ON blood_pressures.patient_id = patients.id')
        .joins('INNER JOIN facilities ON facilities.id = blood_pressures.facility_id')
        .where('facilities.district = ?', @district_name)
        .group('facilities.name', 'facilities.id')
        .order('facilities.name')
        .pluck("facilities.id AS facility_id",
               %Q(sum(CASE
                         WHEN patients.device_created_at < date_trunc('MONTH', now() - interval '2 months')::DATE
                         AND blood_pressures.device_created_at >= date_trunc('MONTH', now() - interval '2 months')::DATE
                         AND blood_pressures.device_created_at <  date_trunc('MONTH', now() - interval '1 month')::DATE THEN 1
                         ELSE 0
                     END) AS #{MONTHLY_FOLLOW_UP_PATIENTS_ATTRS.first}),
               %Q(sum(CASE
                         WHEN patients.device_created_at < date_trunc('MONTH', now() - interval '1 months')::DATE
                         AND blood_pressures.device_created_at >= date_trunc('MONTH', now() - interval '1 months')::DATE
                         AND blood_pressures.device_created_at <  date_trunc('MONTH', now())::DATE THEN 1
                         ELSE 0
                     END) AS #{MONTHLY_FOLLOW_UP_PATIENTS_ATTRS.second}),
               %Q(sum(CASE
                         WHEN patients.device_created_at < date_trunc('MONTH', now())::DATE
                         AND blood_pressures.device_created_at >= date_trunc('MONTH', now())::DATE
                         AND blood_pressures.device_created_at <  date_trunc('MONTH', now() - interval '1 month')::DATE THEN 1
                         ELSE 0
                     END) AS #{MONTHLY_FOLLOW_UP_PATIENTS_ATTRS.third}))

    group_by_facility(@follow_up_patients_by_month, MONTHLY_FOLLOW_UP_PATIENTS_ATTRS)
  end

  def group_by_facility(query_results, attrs)
    query_results.map do |row_values|
      facility_id, *remaining = row_values
      [facility_id, attrs.zip(remaining).to_h]
    end.to_h
  end
end
