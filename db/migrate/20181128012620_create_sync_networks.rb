class CreateSyncNetworks < ActiveRecord::Migration[5.1]
  def change
    create_table :sync_networks, id: :uuid do |t|
      t.string :name
      t.text :description
      t.references :organization, type: :uuid, null:false, foreign_key: true

      t.timestamps
    end

    add_reference :facilities, :sync_network, type: :uuid, foreign_key: true
  end
end
