class MergeExactDuplicatePatients
  include Memery

  def initialize
    @merge_failures = []
  end

  attr_accessor :merge_failures

  def perform
    duplicate_patient_ids.map do |patient_ids|
      DeduplicatePatients.new(Patient.where(id: patient_ids)).merge
    rescue => e
      # Bad data can cause our merge logic to breakdown in unpredictable ways.
      # We want to report any such errors and look into them on a per case basis.
      handle_error(e, patient_ids)
    end

    report_summary
  end

  def handle_error(e, patient_ids)
    error_details = {exception: e, patient_ids: patient_ids}
    merge_failures << error_details

    Sentry.capture_message("Failed to merge duplicate patients", extra: error_details)
  end

  def report_summary
    Rails.logger.info(report_stats.to_json)
    Rails.logger.info "Failed to merge patients #{merge_failures}"
  end

  def report_stats
    {processed: {total: duplicate_patient_ids.flatten.count,
                 distinct: duplicate_patient_ids.count},
     merged: {total: duplicate_patient_ids.flatten.count - merge_failures.flatten.count,
              distinct: duplicate_patient_ids.count - merge_failures.count,
              total_failures: merge_failures.count,
              distinct_failure: merge_failures.flatten.count}}
  end

  memoize def duplicate_patient_ids
    identifier_type = PatientBusinessIdentifier.identifier_types[:simple_bp_passport]

    # This does an exact match based on case insensitive full name only.
    PatientBusinessIdentifier
      .select("identifier, array_agg(patient_id) as patient_ids")
      .joins(:patient)
      .where.not(identifier: "")
      .where(identifier_type: identifier_type)
      .group("identifier, lower(full_name)")
      .having("COUNT(distinct patient_id) > 1")
      .map(&:patient_ids)
  end
end
