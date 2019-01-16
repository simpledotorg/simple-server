class Api::Current::AnalyticsController < APIController
  before_action :in_tz_IST
  after_action :in_tz_UTC

  def in_tz_IST
    Groupdate.time_zone = "New Delhi"
  end

  def in_tz_UTC
    Groupdate.time_zone = "UTC"
  end
end