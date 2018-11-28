class Api::V1::FacilitiesController < Api::Current::FacilitiesController
  include Api::V1::ApiControllerOverrides
  include Api::V1::SyncControllerOverrides

  def transform_to_response(facility)
    Api::Current::FacilityTransformer.to_response(facility)
  end
end
