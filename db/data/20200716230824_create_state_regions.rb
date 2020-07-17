class CreateStateRegions < ActiveRecord::Migration[5.2]
  def up
    StateRegionCreator.new.call
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
