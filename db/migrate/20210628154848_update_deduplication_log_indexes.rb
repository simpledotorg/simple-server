class UpdateDeduplicationLogIndexes < ActiveRecord::Migration[5.2]
  def change
    remove_index :deduplication_logs, name: :index_deduplication_records_lookup
    add_index :deduplication_logs, [:deleted_record_id, :deleted_at], name: :idx_deduplication_logs_lookup_deleted_at
  end
end
