class Api::V1::CommunicationsController < Api::V2::CommunicationsController
  include Api::V1::ApiControllerOverrides
  include Api::V1::SyncControllerOverrides
end
