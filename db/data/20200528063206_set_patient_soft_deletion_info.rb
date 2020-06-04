class SetPatientSoftDeletionInfo < ActiveRecord::Migration[5.2]
  def up
    bot_user = User.find_or_create_by!(full_name: "Data Migration Bot",
                                       sync_approval_status: "denied",
                                       sync_approval_status_reason: "Bot user doesn't require sync") do |user|
      user.device_created_at = Time.current
      user.device_updated_at = Time.current
    end

    Patient.with_discarded.discarded.in_batches(of: 1_000) do |batch|
      batch.update_all(deleted_by_user_id: bot_user.id, deleted_reason: "unknown")
    end
  end

  def down
    Rails.logger.info "This data migration cannot be reversed. Skipping."
  end
end
