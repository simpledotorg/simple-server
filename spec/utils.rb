class Hash
  def with_int_timestamps
    ts_keys = %w[recorded_at created_at updated_at device_created_at device_updated_at age_updated_at otp_valid_until deleted_at]
    each_pair do |key, value|
      if ts_keys.include?(key) && value.present?
        self[key] = value.to_time.to_i
      elsif value.is_a? Hash
        self[key] = value.with_int_timestamps
      elsif value.is_a? Array
        self[key] = value.map(&:with_int_timestamps)
      end
      self
    end
    self
  end

  def to_json_and_back
    JSON(to_json)
  end

  def with_payload_keys
    Api::Current::Transformer.rename_attributes(
      self, Api::Current::Transformer.inverted_key_mapping
    )
  end
end
