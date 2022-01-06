# frozen_string_literal: true

class AnalyticsController < AdminController
  around_action :set_reporting_time_zone
  before_action :set_quarter, only: [:whatsapp_graphics]
  before_action :set_period

  CACHE_VERSION = 1

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
