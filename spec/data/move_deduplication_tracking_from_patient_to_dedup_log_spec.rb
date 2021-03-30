require "rails_helper"
require Rails.root.join("db/data/20210330105500_move_deduplication_tracking_from_patient_to_dedup_log")

RSpec.describe MoveDeduplicationTrackingFromPatientToDedupLog do
  it "copies over dedupe tracking information from Patient to DeduplicationLog" do
    deduped_patient = create(:patient)
    dedupe_time = Time.current
    deleted_patient = create(:patient,
      merged_into_patient: deduped_patient,
      merged_by_user: deduped_patient.registration_user,
      deleted_at: dedupe_time)

    described_class.new.up
    dedup_log = DeduplicationLog.first

    expect(dedup_log.created_at).to eq dedupe_time
    expect(dedup_log.deleted_record).to eq deleted_patient
    expect(dedup_log.deduped_record).to eq deduped_patient
    expect(dedup_log.user).to eq deduped_patient.registration_user
    expect(dedup_log.record_type).to eq "Patient"
  end
end
