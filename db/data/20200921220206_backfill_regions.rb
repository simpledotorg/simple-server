class BackfillRegions < ActiveRecord::Migration[5.2]
  def up
    Region.backfill!
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
