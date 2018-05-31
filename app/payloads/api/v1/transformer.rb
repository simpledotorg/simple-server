module Api::V1::Transformer
  def self.from_request(attributes_of_payload)
    rename_attributes(attributes_of_payload, key_mapping)
  end

  def self.to_response(model)
    rename_attributes(model.attributes, key_mapping.invert.with_indifferent_access).as_json
  end

  def self.rename_attributes(attributes, mapping)
    attributes
      .to_hash
      .transform_keys { |key| mapping[key] || key }
      .with_indifferent_access
  end

  def self.key_mapping
    {
      created_at: :device_created_at,
      updated_at: :device_updated_at
    }.with_indifferent_access
  end
end