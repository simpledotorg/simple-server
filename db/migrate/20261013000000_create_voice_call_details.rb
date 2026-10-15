class CreateVoiceCallDetails < ActiveRecord::Migration[6.1]
  def change
    create_table :voice_call_details do |t|
      t.string :call_request_id, null: false
      t.string :status, null: false
      t.string :outcome
      t.string :suggested_remove_reason
      t.boolean :safety_flag, null: false, default: false
      t.string :confidence
      t.integer :attempts
      t.integer :answered_attempts
      t.datetime :last_attempted_at
      t.integer :connected_seconds
      t.string :provider
      t.string :prompt_version
      t.references :resolved_by_user, type: :uuid, foreign_key: {to_table: :users}
      t.datetime :resolved_at
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :voice_call_details, :call_request_id, unique: true
    add_index :voice_call_details, :status
  end
end
