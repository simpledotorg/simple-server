class RunnerTrace
  prepend SentryHandler
  class Error < StandardError
  end

  attr_reader :logger

  def initialize
    @logger = Rails.logger.child(class: self.class.name)
    @logger.info msg: "runner trace initialized",
      sentry_debug_info: sentry_debug_info
  end

  def call
    Statsd.instance.increment("runner_trace.count")
    logger.info msg: "about to raise an error",
      sentry_debug_info: sentry_debug_info
    raise Error, "Runner trace error"
  end

  def sentry_debug_info
    {
      sentry_env: Sentry.configuration.environment,
      sentry_initialized: Sentry.initialized?,
      sentry_background_threads: Sentry.configuration.background_worker_threads
    }
  end
end
