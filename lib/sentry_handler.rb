# Useful for reporting to Sentry from cron scheduled `runner` tasks - other contexts already have Sentry
# middlewares setup that do this for us.
#
# Example usage:
#
# class MyService
# . prepend SentryHandler
#
#   def call
# .   # do things
# . end
module SentryHandler
  def call
    super
  rescue => exception
    Rails.logger.error("captured exception #{e} in #{self.class.name}, reporting and reraising", exception: exception)
    Sentry.capture_exception(e)
    raise exception
  end
end
