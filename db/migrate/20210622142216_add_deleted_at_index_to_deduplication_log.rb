class AddDeletedAtIndexToDeduplicationLog < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index "deduplication_logs", ["deduped_record_id", "deleted_at"], name: "index_deduplication_records_lookup"
  end
end
