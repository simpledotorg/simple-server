class AddDeduplicationLog < ActiveRecord::Migration[5.2]
  def change
    create_table :deduplication_logs, id: :uuid do |t|
      t.belongs_to :user, null: true, type: :uuid
      t.string :record_type, null: false
      t.string :deleted_record_id, null: false
      t.string :deduped_record_id, null: false
      t.timestamps
      t.index [:record_type, :deleted_record_id], name: "idx_deduplication_logs_lookup_deleted_record", unique: true
    end
  end
end