# frozen_string_literal: true

class MarkTransferredPatient
  TRANSFER_CANCEL_REASONS = %w[moved_to_private public_hospital_transfer]

  def self.call
    latest_appointment_per_patient =
      Appointment
        .select("DISTINCT ON (patient_id) *")
        .order("patient_id, updated_at DESC")

    migrated_patient_ids =
      Appointment
        .from(latest_appointment_per_patient, "appointments")
        .where(cancel_reason: TRANSFER_CANCEL_REASONS)
        .pluck(:patient_id)

    patients = Patient.where(id: migrated_patient_ids)
    Rails.logger.info "Status set to 'migrated' for #{patients.count}"

    patients.map { |patient| patient.update(status: "migrated") }
  end
end
