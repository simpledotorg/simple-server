class AddDefaultAccessLevelToUsers < ActiveRecord::Migration[5.2]
  def up
    User.admins.where(access_level: [nil, ""]).update_all(access_level: "call_center")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
