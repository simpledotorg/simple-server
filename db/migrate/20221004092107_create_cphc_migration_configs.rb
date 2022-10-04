class CreateCphcMigrationConfigs < ActiveRecord::Migration[6.1]
  def change
    create_table :cphc_migration_configs do |t|
      t.uuid :facility_group_id
      t.json :config
      t.timestamp :deleted_at
      t.timestamps
    end

    add_index :cphc_migration_configs, :facility_group_id, unique: true
  end
end
