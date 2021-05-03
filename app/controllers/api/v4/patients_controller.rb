class Api::V4::PatientsController < APIController
  DEFAULT_RETENTION_DURATION = 3600
  RETENTION_TYPES = {temporary: "temporary", permanent: "permanent"}
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:lookup]

  def lookup
    identifiers = PatientBusinessIdentifier.where(identifier: params[:identifier])
    current_state = current_facility.region.state_region
    patients = current_state
      .syncable_patients
      .where(id: identifiers.pluck(:patient_id))

    render(
      json: Oj.dump({
        patients: patients.map { |patient| transform_to_response(patient) },
        # TODO: retention information can be patient specific
        retention: {
          type: RETENTION_TYPES[:temporary],
          duration_seconds: DEFAULT_RETENTION_DURATION
        }
      }, mode: :compat),
      status: :ok
    )
  end

  private

  def transform_to_response(patient)
    Api::V3::PatientTransformer.to_nested_response(patient).merge(
      {
        appointments: patient.appointments.map { |appointment| Api::V3::AppointmentTransformer.to_response(appointment) },
        blood_pressures: patient.blood_pressures.map { |blood_pressure| Api::V3::BloodPressureTransformer.to_response(blood_pressure) },
        blood_sugars: patient.blood_sugars.map { |blood_sugar| Api::V4::BloodSugarTransformer.to_response(blood_sugar) },
        medical_history: Api::V3::MedicalHistoryTransformer.to_response(patient.medical_history),
        prescription_drugs: patient.prescription_drugs.map { |prescription_drug| Api::V3::PrescriptionDrugTransformer.to_response(prescription_drug) }
      # teleconsultations: patient.teleconsultations.map { |teleconsultation| Api::V4::TeleconsultationTransformer.to_response(teleconsultation) }
      }
    )
  end
end
