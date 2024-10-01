module PatientDeduplication
  module Stats
    class << self
      def report(trigger_type, processed, merged, failures)
        opts = {trigger_type: trigger_type}
        Metrics.gauge("patient_deduplications_processed_total", processed, opts)
        Metrics.gauge("patient_deduplications_merged_total", merged, opts)
        Metrics.gauge("patient_deduplications_failures_total", failures, opts)
      end
    end
  end
end
