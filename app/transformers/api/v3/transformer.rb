class Api::V3::Transformer
  class << self
    def from_request(payload_attributes)
      rename_attributes(payload_attributes, from_request_key_mapping)
    end

    def to_response(model)
      rename_attributes(model.attributes, to_response_key_mapping).as_json
    end

    def rename_attributes(attributes, mapping)
      replace_keys(attributes.to_hash, mapping).with_indifferent_access
    end

    def replace_keys(hsh, mapping)
      mapping.each do |k, v|
        hsh[v] = hsh.delete(k)
      end
      hsh
    end

    def from_request_key_mapping
      {
        "created_at" => "device_created_at",
        "updated_at" => "device_updated_at"
      }
    end

    def to_response_key_mapping
      from_request_key_mapping.invert
    end
  end
end
