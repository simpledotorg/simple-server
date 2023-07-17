class CreateMachineUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :machine_users, id: :uuid do |t|
      t.string :name
      t.references :organization, null: false, type: :uuid
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :machine_users, :name
  end
end
