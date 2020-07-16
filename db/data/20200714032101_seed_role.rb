class SeedRole < ActiveRecord::Migration[5.2]
  def up
    admin_permissions = Permission.where(name: [:manage_region, :manage_users, :access_aggregate_data, :access_pii])
    owner_permissions = Permission.where(name: [:manage_region, :manage_users, :access_aggregate_data, :access_pii])

    admin = Role.create(name: :admin)
    admin.permissions << admin_permissions

    owner = Role.create(name: :owner)
    owner.permissions << owner_permissions
  end

  def down
    Role.delete_all
  end
end
