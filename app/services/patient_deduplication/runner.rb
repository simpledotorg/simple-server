module PatientDeduplication
  class Runner
    prepend SentryHandler

    def initialize(duplicate_patient_ids)
      @duplicate_patient_ids = duplicate_patient_ids
      @merge_failures = []
    end

    attr_accessor :merge_failures, :duplicate_patient_ids

    def call
      duplicate_patient_ids.each do |patient_ids|
        deduplicator = Deduplicator.new(Patient.where(id: patient_ids))
        deduplicator.merge
        merge_failures << deduplicator.errors if deduplicator.errors.present?
      end

      report_summary
    end

    def report_summary
      Rails.logger.info(report_stats.to_json)
      Rails.logger.info "Failed to merge patients #{merge_failures}"

      Stats.report(
        "automatic",
        report_stats.dig(:processed, :total),
        report_stats.dig(:merged, :total),
        report_stats.dig(:merged, :total_failures)
      )
    end

    def report_stats
      {processed: {total: duplicate_patient_ids.flatten.count,
                   distinct: duplicate_patient_ids.count},
       merged: {total: duplicate_patient_ids.flatten.count - merge_failures.flatten.count,
                distinct: duplicate_patient_ids.count - merge_failures.count,
                total_failures: merge_failures.flatten.count,
                distinct_failures: merge_failures.count}}
    end
  end
end
