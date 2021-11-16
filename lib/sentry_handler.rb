module SentryHandler
  def call
    super
  rescue => e
    Sentry.capture_exception(e)
    raise e
  end
end
