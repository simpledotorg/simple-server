# frozen_string_literal: true

class CreateAuditLogsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low

  def perform(log_json)
    log_hash = JSON.parse(log_json)
    log_hash["record_ids"].map { |record_id|
      audit_log = {user: log_hash["user_id"],
                   auditable_type: log_hash["record_class"],
                   auditable_id: record_id,
                   action: log_hash["action"],
                   time: log_hash["time"]}

      AuditLog.write_audit_log(audit_log)
    }
  end
end
