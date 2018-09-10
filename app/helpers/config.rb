module Config
  def self.ensure_required_keys_are_present(required_keys: [])
    required_keys.each do |key|
      ENV.fetch(key)
    end
  end
end