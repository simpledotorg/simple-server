class CreateCallResults < ActiveRecord::Migration[5.2]
  def change
    create_table :call_results do |t|
      t.uuid :id, null: false
      t.uuid :user_id, null: false, foreign_key: true
      t.uuid :appointment_id, null: false, foreign_key: true

      t.string :cancel_reason
      t.boolean :agreed_to_visit
      t.timestamp :remind_on

      t.timestamp :device_created_at, null: false
      t.timestamp :device_updated_at, null: false
      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
