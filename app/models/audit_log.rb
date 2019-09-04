class AuditLog < ApplicationRecord
  ACTIONS = %w[fetch create update login invalid touch].freeze
  MERGE_STATUS_TO_ACTION = {
    invalid: 'invalid',
    new: 'create',
    updated: 'update',
    old: 'touch'
  }.freeze

  def self.merge_log(user, record)
    return unless user.present?
    write_audit_log(
      { user: user.id,
        auditable_type: record.class.to_s,
        auditable_id: record.id,
        action: MERGE_STATUS_TO_ACTION[record.merge_status],
        time: Time.now }
    )
  end

  def self.fetch_log(user, record)
    return unless user.present?
    write_audit_log(
      { user: user.id,
        auditable_type: record.class.to_s,
        auditable_id: record.id,
        action: 'fetch',
        time: Time.now }
    )
  end

  def self.login_log(user)
    return unless user.present?
    write_audit_log(
      { user: user.id,
        auditable_type: 'User',
        auditable_id: user.id,
        action: 'login',
        time: Time.now }
    )
  end

  # ActiveRecord callbacks will not be run (if any)
  def self.create_logs_async(user, records, action, time)
    records_by_class = records.group_by { |record| record.class.to_s }

    records_by_class.each do |record_class, records_for_class|
      CreateAuditLogsWorker.perform_async(user.id, record_class, records_for_class.map(&:id), action, time)
    end
  end

  def self.write_audit_log(log)
    AuditLogger.info(log)
  end
end
