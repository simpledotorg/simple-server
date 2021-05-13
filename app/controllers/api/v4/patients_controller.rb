class Api::V4::PatientsController < APIController
  DEFAULT_RETENTION_DURATION_SECONDS = 3600
  RETENTION_TYPES = {temporary: "temporary", permanent: "permanent"}

  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:lookup]
  before_action :validate_identifier_presence, only: [:lookup]

  def lookup
    identifiers = PatientBusinessIdentifier.where(identifier: params[:identifier])
    current_state = current_facility.region.state_region
    patients = current_state
      .syncable_patients
      .where(id: identifiers.pluck(:patient_id))

    return render json: {}, status: :not_found if patients.empty?

    trigger_audit_log(patients)
    render(
      json: Oj.dump({
        patients: patients.map { |patient| transform_to_response(patient) }
      }, mode: :compat),
      status: :ok
    )
  end

  private

  def transform_to_response(patient)
    Api::V3::PatientTransformer.to_nested_response(patient).merge(
      {
        medical_history: Api::V3::MedicalHistoryTransformer.to_response(patient.medical_history),
        appointments: patient.appointments.map { |appointment| Api::V3::AppointmentTransformer.to_response(appointment) },
        blood_pressures: patient.blood_pressures.map { |blood_pressure| Api::V3::BloodPressureTransformer.to_response(blood_pressure) },
        blood_sugars: patient.blood_sugars.map { |blood_sugar| Api::V4::BloodSugarTransformer.to_response(blood_sugar) },
        prescription_drugs: patient.prescription_drugs.map { |prescription_drug| Api::V3::PrescriptionDrugTransformer.to_response(prescription_drug) },
        retention: retention(patient)
      }
    )
  end

  def retention(patient)
    if current_sync_region.syncable_patients.exists?(patient.id)
      {
        type: RETENTION_TYPES[:permanent]
      }
    else
      {
        type: RETENTION_TYPES[:temporary],
        duration_seconds: DEFAULT_RETENTION_DURATION_SECONDS
      }
    end
  end

  def trigger_audit_log(patients)
    PatientLookupAuditLogJob.perform_async(
      {
        user_id: current_user.id,
        facility_id: current_facility.id,
        identifier: params[:identifier],
        patient_ids: patients.pluck(:id),
        time: Time.current
      }.to_json
    )
  end

  def validate_identifier_presence
    head :bad_request if params[:identifier].strip.blank?
  end
end
