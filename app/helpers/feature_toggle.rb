module FeatureToggle
  def self.enabled?(feature_name)
    toggle_name = "ENABLE_#{feature_name}"
    Config.get(toggle_name) == 'true'
  end

  def self.enabled_for_regex?(regex_name, feature_name)
    feature_list_name = "ENABLE_REGEX_#{regex_name}"
    Regexp.new(Config.get(feature_list_name)).match(feature_name)
  end
end