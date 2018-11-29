class Api::V1::ProtocolsController < Api::Current::ProtocolsController
  include Api::V1::ApiControllerOverrides
  include Api::V1::SyncControllerOverrides
end
