require 'json'

class AuditLogFormatter
  def call(severity, time, progname, msg = '')
    msg.to_json + "\n" if msg.present?
  end
end