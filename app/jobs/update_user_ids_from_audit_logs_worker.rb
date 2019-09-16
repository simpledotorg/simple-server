class UpdateUserIdsFromAuditLogsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :audit_log_data_queue

  def perform(record_class, records)
    records.each do |record|
      begin
        db_record = record_class.where(id: record.id)
        db_record.user_id = record.user_id
        db_record.save
      rescue StandardError => e
        puts "#{e.message}\nCouldn't update #{record_class}: #{record}"
      end
    end
  end
end