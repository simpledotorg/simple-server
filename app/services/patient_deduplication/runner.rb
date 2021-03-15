module PatientDeduplication
  class Runner
    include Memery

    def initialize(duplicate_patient_ids)
      @duplicate_patient_ids = duplicate_patient_ids
      @merge_failures = []
    end

    attr_accessor :merge_failures, :duplicate_patient_ids

    def perform
      duplicate_patient_ids.each do |patient_ids|
        Deduplicator.new(Patient.where(id: patient_ids)).merge
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
  end
end
