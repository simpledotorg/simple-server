class Api::V1::AppointmentsController < Api::Current::AppointmentsController
  include Api::V1::ApiControllerOverrides
  include Api::V1::SyncControllerOverrides
end
