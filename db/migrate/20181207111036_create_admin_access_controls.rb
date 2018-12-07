class CreateAdminAccessControls < ActiveRecord::Migration[5.1]
  def change
    create_table :admin_access_controls, id: :uuid do |t|
      t.references :admin, null: false
      t.references :facility_group, type: :uuid, null: false
    end

    add_index :admin_access_controls, [:admin_id, :facility_group_id]
  end
end
