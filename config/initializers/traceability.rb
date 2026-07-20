require "traceability"
require "traceability/log_subscriber"
require "traceability/metrics_subscriber"

ActiveSupport::Notifications.subscribe(Traceability::EVENT_NAME) do |*args|
  payload = ActiveSupport::Notifications::Event.new(*args).payload

  [Traceability::LogSubscriber, Traceability::MetricsSubscriber].each do |subscriber|
    subscriber.call(payload)
  rescue => error
    begin
      Rails.logger.error(
        msg: "traceability_subscriber_error",
        subscriber_class: subscriber.name,
        error_class: error.class.name
      )
    rescue
      nil
    end
  end
end
