class Api::V1::Transformer < Api::V2::Transformer
  def to_response(model)
    rename_attributes(model.attributes, inverted_key_mapping)
      .except('deleted_at')
      .as_json
  end
end