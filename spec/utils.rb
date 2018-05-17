module Utils
  def self.with_int_timestamps(hash)
    ['created_at', 'updated_at', 'updated_on_server_at'].each do |key|
      hash[key] = hash[key].to_i if hash[key].present?
    end
    hash
  end
end