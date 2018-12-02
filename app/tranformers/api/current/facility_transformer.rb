class Api::Current::FacilityTransformer
  class << self
    def to_response(facility)
      Api::Current::Transformer
        .to_response(facility)
        .except('facility_group_id')
    end
  end
end