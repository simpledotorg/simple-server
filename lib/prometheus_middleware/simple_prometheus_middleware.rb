# frozen_string_literal: true

class SimplePrometheusMiddleware < PrometheusExporter::Middleware
  def custom_labels(env)
    {path: env["REQUEST_PATH"]}
  end
end
