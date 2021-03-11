class Api::V4::DrugTransformer < Api::V4::Transformer
  class << self
    def to_response(drug)
      drug
        .as_json["attributes"]
        .merge("protocol" => false,
               "common" => true,
               "created_at" => drug.created_at,
               "updated_at" => drug.updated_at,
               "deleted_at" => drug.deleted_at)
        .except("deleted")
    end
  end
end
