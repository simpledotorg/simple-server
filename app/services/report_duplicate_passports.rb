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
      logger.info msg: "#{duplicate_passports_in_same_facility} passports have duplicate patients in the same facility"
    end

    Statsd.instance.gauge("ReportDuplicatePassports.duplicate_passports.size", duplicate_passports_count)
    Statsd.instance.gauge("ReportDuplicatePassports.duplicate_passports_in_same_facility.size", duplicate_passports_in_same_facility)
  end

  memoize def duplicate_passports_count
    passports_at_multiple_facilities
      .where(identifier: passports_with_multiple_patients)
      .where(identifier_type: IDENTIFIER_TYPES)
      .pluck(:identifier)
      .count
  end

  memoize def duplicate_passports_in_same_facility
    PatientBusinessIdentifier
      .where(identifier: passports_with_multiple_patients_in_same_facility)
      .where(identifier_type: IDENTIFIER_TYPES)
      .pluck(:identifier)
      .count
  end

  memoize def duplicate_passports_across_districts
    PatientBusinessIdentifier
      .where(identifier: passports_with_multiple_patients_across_districts)
      .where(identifier_type: IDENTIFIER_TYPES)
      .pluck(:identifier)
      .count
  end

  def duplicate_passports_without_next_appointments
    identifiers = passports_at_multiple_facilities
                    .where(identifier: passports_with_multiple_patients)
                    .where(identifier_type: IDENTIFIER_TYPES)
                    .where.not(identifier: "")
                    .group(:identifier)

    identifiers.select do |identifier|
      latest_patient = Patient
                         .includes(:latest_scheduled_appointments)
                         .where(id: PatientBusinessIdentifier.where(identifier: identifier).pluck(:patient_id))
                         .order(:recorded_at)
                         .last

      latest_patient&.latest_scheduled_appointment.blank?
    end
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

  def passports_with_multiple_patients_in_same_facility
    PatientBusinessIdentifier
      .group(:identifier)
      .having("COUNT(DISTINCT patient_id) > 1")
      .having("COUNT(DISTINCT #{passport_assigning_facility}) = 1")
      .select(:identifier)
  end

  def passports_with_multiple_patients_across_districts
    PatientBusinessIdentifier
      .joins("INNER JOIN regions facility_region ON facility_region.source_id = COALESCE((metadata->>'assigning_facility_id'), (metadata->>'assigningFacilityUuid'))::uuid")
      .joins("INNER JOIN regions district_region ON district_region.path @> facility_region.path and district_region.region_type = 'district'")
      .group(:identifier)
      .having("COUNT(DISTINCT district_region.id) > 1")
      .having("COUNT(DISTINCT patient_id) > 1")
      .having("COUNT(DISTINCT #{passport_assigning_facility}) > 1")
      .select(:identifier)
  end

  def passports_with_multiple_patients_across_blocks
    PatientBusinessIdentifier
      .joins("INNER JOIN regions facility_region ON facility_region.source_id = COALESCE((metadata->>'assigning_facility_id'), (metadata->>'assigningFacilityUuid'))::uuid")
      .joins("INNER JOIN regions block_region ON block_region.path @> facility_region.path and block_region.region_type = 'block'")
      .group(:identifier)
      .having("COUNT(DISTINCT block_region.id) > 1")
      .having("COUNT(DISTINCT patient_id) > 1")
      .having("COUNT(DISTINCT COALESCE((metadata->'assigning_facility_id'), (metadata->'assigningFacilityUuid'))::text) > 1")
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
