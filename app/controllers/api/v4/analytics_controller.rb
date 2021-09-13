class Api::V4::AnalyticsController < APIController
  around_action :set_reporting_time_zone
end
