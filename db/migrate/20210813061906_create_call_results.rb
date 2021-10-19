class CreateCallResults < ActiveRecord::Migration[5.2]
  def change
    create_table :call_results, id: :uuid do |t|
      t.uuid :user_id, null: false, foreign_key: true
      t.uuid :appointment_id, null: false, foreign_key: true

      t.string :remove_reason
      t.string :result_type, null: false

      t.timestamp :device_created_at, null: false
      t.timestamp :device_updated_at, null: false
      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
