# frozen_string_literal: true

class Api::V3::BloodSugarTransformer < Api::V3::Transformer
  class << self
    def to_response(blood_sugar)
      super(blood_sugar)
        .merge("blood_sugar_value" => blood_sugar["blood_sugar_value"].round(0).to_i)
    end
  end
end
