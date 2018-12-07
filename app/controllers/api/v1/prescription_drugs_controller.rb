class Api::V1::PrescriptionDrugsController < Api::Current::PrescriptionDrugsController
  include Api::V1::ApiControllerOverrides
  include Api::V1::SyncControllerOverrides
end
