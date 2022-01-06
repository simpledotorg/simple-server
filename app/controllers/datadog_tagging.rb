# frozen_string_literal: true

# Tag some key information for Datadog so we can view it across all traces
# See https://docs.datadoghq.com/tracing/guide/add_span_md_and_graph_it/ for more info
module DatadogTagging
  def self.included(base)
    base.helper_method :current_enabled_features
  end

  def current_enabled_features
    @current_enabled_features ||= Flipper.features.select { |feature| feature.enabled?(current_admin) }.map(&:name)
  end

  def set_datadog_tags
    current_span = Datadog.tracer.active_span
    return if current_span.nil?

    current_enabled_features.each do |name|
      current_span.set_tag("features.#{name}", "enabled")
    end

    user_hash = RequestStore.store[:current_user]
    unless user_hash.blank?
      current_span.set_tags(user_hash)
    end
  end
end
