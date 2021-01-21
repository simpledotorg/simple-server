class ReportDuplicatePassports
  include Memery

  IDENTIFIER_TYPES = %w[simple_bp_passport]
  delegate :logger, to: Rails

  def self.report
    new.report
  end

  def report
    logger.tagged("ReportDuplicatePassports") do
      logger.info msg: "#{duplicate_passports_count} passports have duplicate patients across facilities"
    end

    Statsd.instance.gauge("ReportDuplicatePassports.size", duplicate_passports_count)
  end

  memoize def duplicate_passports_count
    passports_at_multiple_facilities
      .where(identifier: passports_with_multiple_patients)
      .where(identifier_type: IDENTIFIER_TYPES)
      .pluck(:identifier)
      .count
  end

  # this is a utility function for fetching the actual duplicate passports
  # you could call this and get counts from it but duplicate_passports_count is faster
  # leaving this here as useful method for debugging
  def duplicate_passports
    PatientBusinessIdentifier
      .where(identifier_type: IDENTIFIER_TYPES)
      .where(identifier: passports_at_multiple_facilities)
      .where(identifier: passports_with_multiple_patients)
  end

  def passports_at_multiple_facilities
    PatientBusinessIdentifier
      .group(:identifier)
      .having("COUNT(DISTINCT #{passport_assigning_facility}) > 1")
      .select(:identifier)
  end

  def passports_with_multiple_patients
    PatientBusinessIdentifier
      .group(:identifier)
      .having("COUNT(DISTINCT patient_id) > 1")
      .select(:identifier)
  end

  private

  def passport_assigning_facility
    "COALESCE((metadata->'assigning_facility_id'), (metadata->'assigningFacilityUuid'))::text"
  end
end
