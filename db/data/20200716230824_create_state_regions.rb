class CreateStateRegions < ActiveRecord::Migration[5.2]
  def up
    Facility.group("lower(state)").pluck("lower(state)").each do |state|
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
