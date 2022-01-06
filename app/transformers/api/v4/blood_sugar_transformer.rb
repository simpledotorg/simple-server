# frozen_string_literal: true

class Api::V4::BloodSugarTransformer < Api::V4::Transformer
  class << self
    def to_response(blood_sugar)
      super(blood_sugar)
        .merge("blood_sugar_value" => blood_sugar["blood_sugar_value"].to_f)
    end
  end
end
