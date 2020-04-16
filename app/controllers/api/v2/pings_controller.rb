class Api::V2::PingsController < Api::V3::PingsController
  include Api::V2::LogApiUsageByUsers
end
