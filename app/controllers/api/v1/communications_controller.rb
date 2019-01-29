class Api::V1::CommunicationsController < Api::Current::CommunicationsController
  include Api::V1::ApiControllerOverrides
  include Api::V1::SyncControllerOverrides
end
