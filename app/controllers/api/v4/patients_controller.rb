class Api::V4::PatientsController < APIController
  DEFAULT_RETENTION_DURATION = 3600
  RETENTION_TYPES = {temporary: "temporary", permanent: "permanent"}
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:lookup]

  def lookup
    identifiers = PatientBusinessIdentifier.where(identifier: params[:identifier])
    current_state = current_facility.region.state_region
    @patients = current_state
      .syncable_patients
      .where(id: identifiers.pluck(:patient_id))

    # TODO: retention information can be patient specific
    @retention_type = RETENTION_TYPES[:temporary]
    @retention_duration = DEFAULT_RETENTION_DURATION
  end
end
