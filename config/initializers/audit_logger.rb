class AuditLogFormatter
  def call(severity, time, progname, msg = '')
    msg + "\n" if msg.present?
  end
end

::AuditLogger ||= Logger.new("#{Rails.root}/log/audit.log")
::AuditLogger.formatter ||= AuditLogFormatter.new