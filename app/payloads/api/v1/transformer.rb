module Api::V1::Transformer
  def self.from_request(attributes_of_payload)
    rename_attributes(attributes_of_payload, key_mapping)
  end

  def self.to_response(model)
    rename_attributes(model.attributes, inverted_key_mapping).as_json
  end

  def self.rename_attributes(attributes, mapping)
    mapping = mapping.with_indifferent_access
    attributes
      .to_hash
      .transform_keys! { |key| mapping[key] || key }
      .with_indifferent_access
  end

  def self.key_mapping
    {
      'created_at' => 'device_created_at',
      'updated_at' => 'device_updated_at'
    }
  end

  def self.inverted_key_mapping
    key_mapping.invert
  end
end