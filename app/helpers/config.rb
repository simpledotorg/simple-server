class Config
  @@config = {}

  def self.configure(required_keys: [])
    required_keys.each do |key|
      @@config[key] = ENV.fetch(key)
    end
    other_keys = ENV.keys - required_keys
    other_keys.each do |key|
      @@config[key] = ENV[key]
    end
  end

  def self.get(key)
    @@config[key]
  end
end