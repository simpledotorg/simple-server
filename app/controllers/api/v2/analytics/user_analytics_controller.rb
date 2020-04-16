class Api::V2::Analytics::UserAnalyticsController < Api::V3::Analytics::UserAnalyticsController
  include Api::V2::LogApiUsageByUsers
end
