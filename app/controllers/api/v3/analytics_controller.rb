class Api::V3::AnalyticsController < APIController
  around_action :set_time_zone

  private

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || DEFAULT_ANALYTICS_TIME_ZONE

    Groupdate.time_zone = time_zone
    Time.use_zone(time_zone) do
      yield
    end

  ensure
    # Make sure we reset the timezone
    Groupdate.time_zone = "UTC"
  end
end
