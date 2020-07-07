class CreateMasterUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :master_users, id: :uuid do |t|
      t.string :full_name

      t.string :sync_approval_status, null: false
      t.string :sync_approval_status_reason, null: true

      t.datetime :device_updated_at, null: false
      t.datetime :device_created_at, null: false

      t.timestamps

      # This is for discard gem
      t.datetime :deleted_at, null: true
    end
  end
end
