class CreateCallLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :call_logs do |t|
      t.string :session_id
      t.string :result
      t.string :action
      t.integer :duration
      t.string :callee_phone_number, null: false
      t.timestamp :start_time
      t.timestamp :end_time
      t.timestamps
    end

    add_reference :call_logs, :user, type: :uuid, null: false
  end
end
