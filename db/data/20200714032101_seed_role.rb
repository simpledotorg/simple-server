class SeedRole < ActiveRecord::Migration[5.2]
  def up
    Role.create(name: "super_admin")
    Role.create(name: "admin")
    Role.create(name: "analyst")
  end

  def down
    Role.delete_all
  end
end
