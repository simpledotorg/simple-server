class Api::Current::FacilityTransformer
  class << self
    def to_response(facility)
      Api::Current::Transformer.to_response(facility)
        .except('enable_diabetes_management')
        .merge(config: { enable_diabetes_management: facility.enable_diabetes_management },
               protocol_id: facility.protocol.try(:id))
    end
  end
end