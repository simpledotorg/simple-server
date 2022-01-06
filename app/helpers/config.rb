# frozen_string_literal: true

module Config
  def self.ensure_required_keys_are_present(required_keys: [])
    required_keys.sort.each do |key|
      ENV.fetch(key)
    end
  end

  def self.ensure_required_keys_have_fallbacks(required_keys: {})
    required_keys.each do |key, fallback|
      ENV.fetch(key)
    rescue KeyError
      ENV.fetch(fallback)
    end
  end

  def self.get_int(config_key_name, default_value)
    (ENV[config_key_name] || default_value).to_i
  end
end
