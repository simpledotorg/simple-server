module EnvHelper
  def self.ensure_required_keys_are_present(required_keys: [])
    required_keys.sort.each do |key|
      ENV.fetch(key)
    end
  end

  def self.get_int(config_key_name, default_value)
    (ENV[config_key_name] || default_value).to_i
  end
end
