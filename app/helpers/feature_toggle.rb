# frozen_string_literal: true

module FeatureToggle
  def self.enabled?(feature_name)
    toggle_name = "ENABLE_#{feature_name}"
    ENV[toggle_name] == "true"
  end

  def self.enabled_for_regex?(regex_name, feature_name)
    feature_list_name = "ENABLE_REGEX_#{regex_name}"
    Regexp.new(ENV[feature_list_name]).match(feature_name)
  end
end
