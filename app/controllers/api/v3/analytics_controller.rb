class Api::V3::AnalyticsController < APIController
  around_action :set_reporting_time_zone
end
