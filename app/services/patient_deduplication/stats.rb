# frozen_string_literal: true

module PatientDeduplication
  module Stats
    class << self
      def report(trigger_type, processed, merged, failures)
        opts = {tags: [trigger_type]}
        Statsd.instance.count("PatientDeduplication.total_processed", processed, opts)
        Statsd.instance.count("PatientDeduplication.total_merged", merged, opts)
        Statsd.instance.count("PatientDeduplication.total_failures", failures, opts)
      end
    end
  end
end
