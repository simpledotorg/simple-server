class Api::V3::Transformer
  class << self
    def from_request(attributes_of_payload)
      rename_attributes(attributes_of_payload, key_mapping)
    end

    def to_response(model)
      rename_attributes(model.attributes, inverted_key_mapping).as_json
    end

    def rename_attributes(attributes, mapping)
      replace_keys(attributes
        .to_hash
        .except(*mapping.values), mapping)
        .with_indifferent_access
    end

    def replace_keys(h, mapping)
      mapping.each do |k, v|
        h[v] = h.delete(k)
      end
      h
    end

    def key_mapping
      {
        "created_at" => "device_created_at",
        "updated_at" => "device_updated_at"
      }
    end

    def inverted_key_mapping
      key_mapping.invert
    end
  end
end
