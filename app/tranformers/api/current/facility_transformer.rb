class Api::Current::FacilityTransformer
  class << self
    def to_response(facility)
      Api::Current::Transformer
        .to_response(facility)
        .except('sync_network_id')
    end
  end
end