# frozen_string_literal: true

class Api::V4::MedicationTransformer < Api::V4::Transformer
  class << self
    def to_response(medication)
      medication
        .as_json["attributes"]
        .merge("protocol" => "no",
          "common" => "yes",
          "created_at" => medication.created_at,
          "updated_at" => medication.updated_at,
          "deleted_at" => medication.deleted_at)
        .except("deleted")
    end
  end
end
