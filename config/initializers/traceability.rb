require "traceability"
require "traceability/log_subscriber"
require "traceability/metrics_subscriber"

ActiveSupport::Notifications.subscribe(Traceability::EVENT_NAME) do |*args|
  payload = ActiveSupport::Notifications::Event.new(*args).payload

  Traceability::LogSubscriber.call(payload)
  Traceability::MetricsSubscriber.call(payload)
end
