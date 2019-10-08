class ExportAuditLogsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :audit_log_data_queue

  def perform(date_str, json_logs)
    export_logger = Logger.new("#{Rails.root}/log/audit.log-#{date_str.tr('-', '')}")
    export_logger.formatter = AuditLogFormatter.new
    logs = JSON.parse(json_logs)
    logs.each do |log|
      export_logger.info(log.slice('auditable_type', 'auditable_id', 'user_id', 'action')
                           .merge('time' => log['created_at'])
                           .to_json)
    end
  end
end