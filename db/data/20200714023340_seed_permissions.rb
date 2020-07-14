class SeedPermissions < ActiveRecord::Migration[5.2]
  def up
    Permission.create([{name: "manage_region"},
      {name: "manage_users"},
      {name: "access_aggregate_data"},
      {name: "access_pii"}])
  end

  def down
    Permission.delete_all
  end
end
