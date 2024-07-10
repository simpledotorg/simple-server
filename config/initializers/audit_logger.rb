class AuditLogFormatter
  def call(severity, time, progname, msg = "")
    msg + "\n" if msg.present?
  end
end

unless ENV['DISABLE_AUDIT_LOGGING'] == 'true'
  ::AuditLogger = Logger.new("#{Rails.root}/log/audit.log")
  ::AuditLogger.formatter = AuditLogFormatter.new

  ::PatientLookupAuditLogger = Logger.new("#{Rails.root}/log/patient_lookup_audit.log")
  ::PatientLookupAuditLogger.formatter = AuditLogFormatter.new
end
