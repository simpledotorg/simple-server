class UpdateUserIdsFromAuditLogsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :audit_log_data_queue

  def perform(record_class_string, records)
    record_class = record_class_string.safe_constantize
    records.each do |record|
      begin
        db_record = record_class.where(id: record['id']).first
        db_record.user_id = record['user_id']
        db_record.save
      rescue StandardError => e
        Rails.logger.info("#{e.message}\nCouldn't update #{record_class_string}: #{db_record} with #{record}")
      end
    end
  end
end