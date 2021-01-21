class CreateAdminAccessControls < ActiveRecord::Migration[5.1]
  def change
    create_table :admin_access_controls, id: :uuid do |t|
      t.references :admin, null: false
      t.uuid :access_controllable_id, null: false
      t.string :access_controllable_type, null: false

      t.timestamps
    end

    add_index :admin_access_controls, [:access_controllable_id, :access_controllable_type], name: "index_access_controls_on_controllable_id_and_type"
  end
end
