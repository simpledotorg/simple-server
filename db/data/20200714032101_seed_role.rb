class SeedRole < ActiveRecord::Migration[5.2]
  def up
    permissions = Permission.where(name: %w[manage_region manage_users access_aggregate_data access_pii])

    admin = Role.create(name: "admin")
    admin.permissions << permissions
  end

  def down
    Role.delete_all
  end
end
