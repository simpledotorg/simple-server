class AddDeduplicationLog < ActiveRecord::Migration[5.2]
  def change
    create_table :deduplication_logs, id: :uuid do |t|
      t.belongs_to :user, null: false, type: :uuid
      t.string :record_type, null: false
      t.uuid :deleted_record_id, null: false
      t.uuid :deduped_record_id, null: false
      t.timestamps
      t.index [:record_type, :deleted_record_id], name: "idx_deduplication_logs_lookup_deleted_record", unique: true
    end
  end
end