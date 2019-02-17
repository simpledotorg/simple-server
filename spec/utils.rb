class Hash
  def with_int_timestamps
    ts_keys = %w[created_at updated_at device_created_at device_updated_at age_updated_at otp_valid_until deleted_at]
    self.each_pair do |key, value|
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
    JSON(self.to_json)
  end

  def with_payload_keys
    Api::V1::Transformer.rename_attributes(
      self, Api::V1::Transformer.inverted_key_mapping)
  end
end

def random_time(from_time, to_time)
  Time.at(from_time.to_time.to_f + rand * (to_time.to_time - from_time.to_time).to_f)
end

def create_in_period(model_type, trait: nil, from_time:, to_time:, **options)
  create model_type, trait, options.merge(device_created_at: random_time(from_time, to_time))
end

def create_list_in_period(model_type, count, trait: nil, from_time:, to_time:, **options)
  created_objects = []
  count.times do
    created_objects << create_in_period(
      model_type,
      trait: trait,
      from_time: from_time,
      to_time: to_time,
      **options
    )
  end
  created_objects
end