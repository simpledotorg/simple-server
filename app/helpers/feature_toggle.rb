module FeatureToggle
  def self.is_enabled?(feature_name)
    toggle_name = "ENABLE_#{feature_name}"
    ENV[toggle_name] == 'true'
  end

  def self.is_enabled_for_regex?(regex_name, feature_name)
    feature_list_name = "ENABLED_REGEX_MATCH_FOR_#{regex_name}"
    Regexp.new(ENV[feature_list_name]).match(feature_name)
  end
end