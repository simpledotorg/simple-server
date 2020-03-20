class Api::V3::AnalyticsController < APIController
  before_action :set_timezone_to_IST
  after_action :set_timezone_to_UTC

  private

  def set_timezone_to_IST
    Groupdate.time_zone = "Asia/Kolkata"
  end

  def set_timezone_to_UTC
    Groupdate.time_zone = "UTC"
  end
end
