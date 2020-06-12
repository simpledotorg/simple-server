class RemoveAdherenceTabPermissions < ActiveRecord::Migration[5.2]
  def up
    UserPermission.where(permission_slug: "view_adherence_follow_up_list").destroy_all
  end

  def down
    Rails.logger.info "This data migration cannot be reversed. Skipping."
  end
end
