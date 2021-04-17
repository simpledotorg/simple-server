class MoveDeduplicationTrackingFromPatientToDedupLog < ActiveRecord::Migration[5.2]
  def up
    deleted_patients = Patient.with_discarded.discarded.where("merged_into_patient_id IS NOT NULL")

    deleted_patients.each do |patient|
      DeduplicationLog.create(
        user_id: patient.merged_by_user_id,
        record_type: Patient.to_s,
        deduped_record_id: patient.merged_into_patient_id,
        deleted_record_id: patient.id,
        created_at: patient.deleted_at
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
