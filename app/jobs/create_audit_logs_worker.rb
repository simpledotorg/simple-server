class CreateAuditLogsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :audit_log_queue

  def perform(log_json)
    log_hash = JSON.parse(log_json)
    audit_logs = log_hash["record_ids"].map do |record_id|
      { user: log_hash["user_id"],
        auditable_type: log_hash["record_class"],
        auditable_id: record_id,
        action: log_hash["action"],
        time: log_hash["time"] }
    end
    audit_logs.each do |audit_log|
      AuditLog.write_audit_log(audit_log)
    end
  end
end
