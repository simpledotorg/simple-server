module Traceability
  EVENT_NAME = "traceability.simple".freeze
  CONTEXT_KEY = :traceability_context

  SAFE_FIELDS = %i[
    phase boundary operation resource request_id idempotency_key
    controller action http_method path user_id facility_id
    outcome duration_ms error_class status
    input_count output_count error_count audit_count record_id
    authenticated facility_present sync_region_id
  ].freeze

  METRIC_LABEL_FIELDS = %i[boundary operation resource outcome].freeze

  module_function

  def trace(boundary:, operation:, attributes: {})
    started_at = monotonic_time
    finish_attributes = sanitize(attributes)
    base_payload = context.merge(finish_attributes).merge(
      boundary: boundary,
      operation: operation
    )

    publish(base_payload.merge(phase: "start"))

    result = yield(finish_attributes)
    finish_attributes[:outcome] ||= "success"
    result
  rescue => error
    finish_attributes ||= {}
    finish_attributes[:outcome] = "error"
    finish_attributes[:error_class] = error.class.name
    raise
  ensure
    if started_at
      finish_payload = context
        .merge(sanitize(finish_attributes || {}))
        .merge(
          boundary: boundary,
          operation: operation,
          phase: "finish",
          duration_ms: ((monotonic_time - started_at) * 1000).round(2)
        )
      publish(finish_payload)
    end
  end

  def with_context(attributes)
    context_existed = RequestStore.store.key?(CONTEXT_KEY)
    previous_context = RequestStore.store[CONTEXT_KEY]
    RequestStore.store[CONTEXT_KEY] = sanitize(attributes)
    yield
  ensure
    if context_existed
      RequestStore.store[CONTEXT_KEY] = previous_context
    else
      RequestStore.store.delete(CONTEXT_KEY)
    end
  end

  def add_context(attributes)
    return unless active?

    RequestStore.store[CONTEXT_KEY] = context.merge(sanitize(attributes))
  end

  def active?
    RequestStore.store[CONTEXT_KEY].present?
  end

  def context
    RequestStore.store[CONTEXT_KEY] || {}
  end

  def sanitize(attributes)
    attributes.to_h.symbolize_keys.slice(*SAFE_FIELDS)
  end

  def publish(payload)
    ActiveSupport::Notifications.instrument(EVENT_NAME, sanitize(payload))
  rescue => error
    begin
      Rails.logger.error(msg: "traceability_publish_error", error_class: error.class.name)
    rescue
      nil
    end
  end

  def monotonic_time
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
