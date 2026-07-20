module SyncTraceable
  extend ActiveSupport::Concern

  included do
    prepend_around_action :trace_sync_request, if: :sync_trace_action?
  end

  private

  def trace_sync_request
    Traceability.with_context(
      request_id: request.request_id,
      idempotency_key: request.headers["Idempotency-Key"]
    ) do
      Traceability.trace(
        boundary: "request",
        operation: "#{controller_path}##{action_name}",
        attributes: {
          controller: controller_path,
          action: action_name,
          http_method: request.request_method,
          path: request.path
        }
      ) do |finish|
        result = yield
        finish[:status] = response.status
        finish[:outcome] = response.status < 400 ? "success" : "error"
        result
      rescue => error
        finish[:status] = ActionDispatch::ExceptionWrapper.status_code_for_exception(error.class.name)
        raise
      end
    end
  end

  def sync_trace_action?
    %w[sync_from_user sync_to_user].include?(action_name)
  end
end
