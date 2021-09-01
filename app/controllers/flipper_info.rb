# Expose currently enabled features from Flipper for admin / dashboard requests
module FlipperInfo
  def self.included(base)
    base.helper_method :current_enabled_features
  end

  def current_enabled_features
    @current_enabled_features ||= Flipper.features.select { |feature| feature.enabled?(current_admin) }.map(&:name)
  end

  def set_enabled_features_as_datadog_tags
    current_span = Datadog.tracer.active_span
    return if current_span.nil?
    current_span.set_tag(:enabled_features, current_enabled_features.map(&:to_s))
  end
end
