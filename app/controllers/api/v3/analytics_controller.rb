class Api::V3::AnalyticsController < APIController
  around_action :set_time_zone
end
