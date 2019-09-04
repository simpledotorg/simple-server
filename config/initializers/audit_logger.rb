require 'json'

class AuditLogFormatter
  def call(severity, time, progname, msg = '')
    msg.to_json + "\n" if msg.present?
  end
end

::AuditLogger ||= Logger.new("#{Rails.root}/log/audit.log")
::AuditLogger.formatter ||= AuditLogFormatter.new