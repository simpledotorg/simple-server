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
      data.merge!(datadog_trace_info) unless Rails.env.test? # don't merge the datadog trace info in test, as it clutters up logs
      if RequestStore.store[:current_user_id]
        data[:current_user_id] = RequestStore.store[:current_user_id]
      end
    end

    after_initialize if respond_to? :after_initialize
  end

  def create_formatter
    if Rails.env.development? || Rails.env.test?
      Ougai::Formatters::Readable.new
    else
      Ougai::Formatters::Bunyan.new
    end
  end
end
