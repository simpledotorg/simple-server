class JsonLogger < Ougai::Logger
  include ActiveSupport::LoggerThreadSafeLevel
  include LoggerSilence

  def initialize(*args)
    super
    @before_log = lambda do |data|
      correlation = Datadog.tracer.active_correlation
      datadog_trace_info = {
        dd: {
          # To preserve precision during JSON serialization, use strings for large numbers
          trace_id: correlation.trace_id.to_s,
          span_id: correlation.span_id.to_s,
          service: correlation.service.to_s,
          version: correlation.version.to_s
        },
        ddsource: ["ruby"]
      }
      # Only merge datadog info if Datadog is enabled, as it clutters up the logs
      data.merge!(datadog_trace_info) if DATADOG_ENABLED
      if RequestStore.store[:current_user]
        data[:usr] = RequestStore.store[:current_user]
      end
    end

    after_initialize if respond_to? :after_initialize
  end

  def create_formatter
    LoggingExtensions.default_log_formatter
  end
end
