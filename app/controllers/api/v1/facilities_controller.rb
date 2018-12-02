class Api::V1::FacilitiesController < Api::Current::FacilitiesController
  include Api::V1::ApiControllerOverrides
  include Api::V1::SyncControllerOverrides
end
