class CreateAuditLogsJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(user_id, record_class, record_ids, action)
    user = User.find(user_id)
    audit_logs = record_ids.map do |record_id|
      AuditLog.new({ user: user,
                     auditable_type: record_class,
                     auditable_id: record_id,
                     action: action })
    end
    AuditLog.import!(audit_logs, validate: true)
  end
end
