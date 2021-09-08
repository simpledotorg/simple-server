class EarliestPatientDataQuery
  def self.call(region)
    new.call(region)
  end

  def call(region)
    return nil if region.facilities.blank?
    parameters = {
      facility_ids: region.facility_ids,
      hypertension: "yes"
    }
    sql = GitHub::SQL.new(<<~SQL, parameters)
      SELECT min(patients.recorded_at) as recorded_at
      FROM patients
      INNER JOIN medical_histories mh
       ON patients.id = mh.patient_id
      LEFT JOIN facilities assigned
        ON patients.assigned_facility_id = assigned.id
      LEFT JOIN facilities registered
        ON patients.registration_facility_id = registered.id
      WHERE patients.deleted_at IS NULL
        AND mh.hypertension = :hypertension
        AND (patients.assigned_facility_id in :facility_ids OR patients.registration_facility_id in :facility_ids)
    SQL
    return nil if sql.values.first.blank?
    # we store timestamps in UTC in the app tables
    Time.find_zone("UTC").parse(sql.values.first).in_time_zone(Time.zone)
  end
end
