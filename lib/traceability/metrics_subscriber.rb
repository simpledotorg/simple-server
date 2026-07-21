module Traceability
  module MetricsSubscriber
    module_function

    def call(payload)
      return unless payload[:phase] == "finish"

      labels = payload.slice(*METRIC_LABEL_FIELDS).compact

      Metrics.increment("simple_boundary_operations_total", labels)
      Metrics.histogram("simple_boundary_duration_seconds", payload[:duration_ms] / 1000.0, labels)
    end
  end
end
