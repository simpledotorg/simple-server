class Api::V2::UsersController < Api::V3::UsersController
  include Api::V2::LogApiUsageByUsers
end
