# frozen_string_literal: true

class SimplePrometheusMiddleware < PrometheusExporter::Middleware
  def custom_labels(env)
    {path: env["PATH_INFO"]}
  end
end
