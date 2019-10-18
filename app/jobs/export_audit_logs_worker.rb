class ExportAuditLogsWorker
  include Sidekiq::Worker
  require 'zlib'

  sidekiq_options queue: :audit_log_data_queue

  def perform(date_str)
    date = Date.parse(date_str)
    file_path = "#{Rails.root}/log/audit.log-#{date_str.tr('-', '')}"
    if AuditLog.where(created_at: date.all_day).count.positive?
      export_logger = Logger.new(file_path)
      export_logger.formatter = AuditLogFormatter.new
      batch_size = ENV.fetch('EXPORT_AUDIT_LOGS_BATCH_SIZE').to_i

      AuditLog.where(created_at: date.all_day).in_batches(of: batch_size) do |batch|
        batch.each do |log|
          export_logger.info(log.slice('auditable_type', 'auditable_id', 'user_id', 'action')
                               .merge('time' => log['created_at'])
                               .to_json)
        end
      end
      Zlib::GzipWriter.open("#{file_path}.gz") do |gz|
        File.open(file_path) do |file|
          while chunk = file.read(16*1024) do
            gz.write(chunk)
          end
        end
      end

      File.delete(file_path)
    end
  end
end