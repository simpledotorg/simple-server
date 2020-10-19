class RemoveAdherenceTabPermissions < ActiveRecord::Migration[5.2]
  def up
    # Since the underlying UserPermission class is deleted, this migration is a no-op
    # UserPermission.where(permission_slug: "view_adherence_follow_up_list").destroy_all
    Rails.logger.info "This data migration is a no-op. Skipping."
  end

  def down
    Rails.logger.info "This data migration cannot be reversed. Skipping."
  end
end
