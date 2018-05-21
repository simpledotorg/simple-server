class Hash
  def with_int_timestamps
    ts_keys = %w(created_at updated_at updated_on_server_at)
    self.each_pair do |key, value|
      if ts_keys.include?(key) && value.present?
        self[key] = value.to_i
      elsif value.is_a? Hash
        self[key] = value.with_int_timestamps
      elsif value.is_a? Array
        self[key] = value.map(&:with_int_timestamps)
      end
      self
    end
    self
  end
end