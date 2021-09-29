class Api::V4::PatientsController < APIController
  RETENTION_TYPES = {temporary: "temporary", permanent: "permanent"}

  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:lookup]

  def lookup
    identifiers = PatientBusinessIdentifier.where(identifier: identifier)
    current_state = current_facility.region.state_region
    patients = Patient
      .where(id: identifiers.pluck(:patient_id))
      .where(id: current_state.syncable_patients)

    return render json: {}, status: :not_found if patients.empty?

    trigger_audit_log(patients)
    render(
      json: Oj.dump({
        patients: patients.map do |patient|
          retention = retention(patient)
          Statsd.instance.increment("OnlineLookup.#{retention[:type]}", tags: [current_state.name, current_user.id])
          Api::V4::PatientLookupTransformer.to_response(patient, retention)
        end
      }, mode: :compat),
      status: :ok
    )
  end

  private

  def retention(patient)
    if current_sync_region.syncable_patients.exists?(patient.id)
      {
        type: RETENTION_TYPES[:permanent]
      }
    else
      {
        type: RETENTION_TYPES[:temporary],
        duration_seconds: Integer(ENV["TEMPORARY_RETENTION_DURATION_SECONDS"])
      }
    end
  end

  def trigger_audit_log(patients)
    PatientLookupAuditLogJob.perform_async(
      {
        user_id: current_user.id,
        facility_id: current_facility.id,
        identifier: identifier,
        patient_ids: patients.pluck(:id),
        time: Time.current
      }.to_json
    )
  end

  def identifier
    params.require(:identifier)
  end
end
