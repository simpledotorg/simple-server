class UpdateUserIdsFromAuditLogsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :audit_log_data_queue

  def perform(record_class_string, records)
    record_class = record_class_string.safe_constantize
    records.each do |record|
      db_record = record_class.find_by(id: record['id'])
      db_record.update_column(:user_id, record['user_id'])
    end
  end
end