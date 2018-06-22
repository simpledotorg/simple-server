module FeatureToggle
  def self.is_enabled?(feature_name)
    toggle_name = "ENABLE_#{feature_name}"
    ENV[toggle_name] == 'true'
  end
end