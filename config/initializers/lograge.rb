Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.custom_options = lambda do |event|
    exceptions = %w[controller action format id]
    correlation = Datadog.tracer.active_correlation
    {
      dd: {
        # To preserve precision during JSON serialization, use strings for large numbers
        trace_id: correlation.trace_id.to_s,
        span_id: correlation.span_id.to_s,
        service: correlation.service.to_s,
        version: correlation.version.to_s
      },
      ddsource: ["ruby"],
      cache_stats: RequestStore[:cache_stats],
      params: event.payload[:params].except(*exceptions)
    }
  end
  config.lograge.formatter = Class.new do |fmt|
    def fmt.call(data)
      {msg: "request"}.merge(data)
    end
  end
end

ActiveSupport::Notifications.subscribe(/cache_read.*\.active_support/) do |name, start, finish, arg1, arg2|
  RequestStore[:cache_stats] ||= {}
  RequestStore[:cache_stats][:read] ||= 0
  RequestStore[:cache_stats][:read] += 1
end

ActiveSupport::Notifications.subscribe(/cache_.*\.active_support/) do |name, start, finish, arg1, arg2|
  Rails.logger.info name: name, start: start, finish: finish, arg1: arg1, arg2: arg2
end
