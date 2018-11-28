class CreateSyncNetworks < ActiveRecord::Migration[5.1]
  def change
    create_table :sync_networks do |t|
      t.string :name
      t.text :description
      t.references :organisation, type: :uuid, null:false, foreign_key: true

      t.timestamps
    end
  end
end
