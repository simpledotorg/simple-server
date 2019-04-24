class Api::V1::PrescriptionDrugsController < Api::V2::PrescriptionDrugsController
  include Api::V1::ApiControllerOverrides
  include Api::V1::SyncControllerOverrides
end
