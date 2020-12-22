class ReportDuplicatePassports
  class << self
    IDENTIFIER_TYPES = %w[simple_bp_passport]

    def report
      Rails.logger.info msg: "#{duplicate_passports_count} passports have duplicate patients across facilities"
      Statsd.instance.gauge("passports_with_duplicate_patients_across_facilities", duplicate_passports_count)
    end

    def duplicate_passports
      PatientBusinessIdentifier
        .where(identifier_type: IDENTIFIER_TYPES)
        .where(identifier: passports_at_multiple_facilities)
        .where(identifier: passports_with_multiple_patients)
    end

    def duplicate_passports_count
      passports_at_multiple_facilities
        .where(identifier: passports_with_multiple_patients)
        .where(identifier_type: IDENTIFIER_TYPES)
        .pluck(:identifier)
        .count
    end

    def passports_at_multiple_facilities
      PatientBusinessIdentifier
        .group(:identifier)
        .having("COUNT(DISTINCT #{passport_assigning_facility}) > 1")
        .select(:identifier)
    end

    def passport_assigning_facility
      "COALESCE((metadata->'assigning_facility_id'), (metadata->'assigningFacilityUuid'))::text"
    end

    def passports_with_multiple_patients
      PatientBusinessIdentifier
        .group(:identifier)
        .having("COUNT(DISTINCT patient_id) > 1")
        .select(:identifier)
    end
  end
end
