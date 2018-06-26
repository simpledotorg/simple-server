module FeatureToggle
  def self.is_enabled?(feature_name)
    toggle_name = "ENABLE_#{feature_name}"
    ENV[toggle_name] == 'true'
  end

  def self.is_enabled_in_list?(list_name, feature_name)
    feature_list_name = "ENABLED_LIST_FOR_#{list_name}"
    ENV[feature_list_name].split(',').include?(feature_name)
  end
end