class AnalyticsController < AdminController
  around_action :set_time_zone
  before_action :set_quarter, only: [:whatsapp_graphics]
  before_action :set_period

  skip_after_action :verify_authorized, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  skip_after_action :verify_policy_scoped, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }
  after_action :verify_authorization_attempted, if: -> { Flipper.enabled?(:new_permissions_system_aug_2020, current_admin) }

  DEFAULT_ANALYTICS_TIME_ZONE = "Asia/Kolkata"

  def set_time_zone
    time_zone = Rails.application.config.country[:time_zone] || DEFAULT_ANALYTICS_TIME_ZONE

    Groupdate.time_zone = time_zone

    Time.use_zone(time_zone) do
      yield
    end

    # Make sure we reset the timezone
    Groupdate.time_zone = "UTC"
  end

  def set_period
    # Store the period in the session for consistency across views.
    # Explicit 'period=X' param overrides the session variable.
    @period = if params[:period].present?
      params[:period].to_sym
    elsif session[:period].present?
      session[:period].to_sym
    else
      :month
    end
    unless [:quarter, :month].include?(@period)
      raise ArgumentError, "Invalid period set #{@period}"
    end

    session[:period] = @period

    @prev_periods = @period == :quarter ? 5 : 6
  end

  def set_quarter
    @year, @quarter = previous_year_and_quarter
    @quarter = params[:quarter].to_i if params[:quarter].present?
    @year = params[:year].to_i if params[:year].present?
  end
end
