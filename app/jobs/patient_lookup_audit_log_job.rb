# frozen_string_literal: true

class PatientLookupAuditLogJob
  include Sidekiq::Worker

  sidekiq_options queue: :low

  def perform(log_json)
    PatientLookupAuditLogger.info(log_json)
  end
end
