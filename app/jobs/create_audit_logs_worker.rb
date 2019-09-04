class CreateAuditLogsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :audit_log_queue

  def perform(user_id, record_class, record_ids, action, time)
    audit_logs = record_ids.map do |record_id|
      { user: user_id,
        auditable_type: record_class,
        auditable_id: record_id,
        action: action,
        time: time }
    end
    audit_logs.each do |audit_log|
      AuditLog.write_audit_log(audit_log)
    end
  end
end
