class AnalyticsController < AdminController
  around_action :set_time_zone
  before_action :set_quarter, only: [:whatsapp_graphics]
  before_action :set_period

  DEFAULT_ANALYTICS_TIME_ZONE = 'Asia/Kolkata'

  def set_time_zone
    time_zone = ENV['ANALYTICS_TIME_ZONE'] || DEFAULT_ANALYTICS_TIME_ZONE

    Groupdate.time_zone = time_zone

    Time.use_zone(time_zone) do
      yield
    end

    # Make sure we reset the timezone
    Groupdate.time_zone = "UTC"
  end

  def set_period
    Rails.logger.debug(params)
    @period = params[:period].present? ? params[:period].to_sym : :month
    @prev_periods = (@period == :month) ? 6 : 3
  end

  def set_quarter
    @quarter = params[:quarter].present? ? params[:quarter].to_i : current_quarter
    @year = params[:year].present? ? params[:year].to_i : current_year
  end

  def set_analytics_cache(key, data)
    Rails.cache.fetch(key, expires_in: ENV.fetch('ANALYTICS_DASHBOARD_CACHE_TTL')) { data }
  end

  def analytics_cache_key_cohort(period)
    "#{analytics_cache_key}/cohort/#{period}"
  end

  def analytics_cache_key_dashboard(time_period)
    key = "#{analytics_cache_key}/dashboard/#{time_period}"
    key = "#{key}/#{@quarter}/#{@year}" if @quarter && @year
    key
  end
end
