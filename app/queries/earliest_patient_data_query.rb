class EarliestPatientDataQuery
  def self.call(*args)
    new(*args).call
  end

  def initialize(region)
    @region = region
  end

  def call
    return nil if @region.facilities.blank?
    parameters = {
      facility_ids: @region.facilities.pluck(:id),
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
    Time.zone.parse(sql.values.first)
  end
end
