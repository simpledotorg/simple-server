class UserAnalyticsPresenter
  include ApplicationHelper
  include DayHelper
  include PeriodHelper
  include DashboardHelper
  include ActionView::Helpers::NumberHelper
  include BustCache

  def initialize(current_facility)
    @current_facility = current_facility.source
  end

  attr_reader :current_facility

  DAYS_AGO = 30
  MONTHS_AGO = 6
  HTN_CONTROL_MONTHS_AGO = 12
  TROPHY_MILESTONES = [10, 25, 50, 100, 250, 500, 1_000, 2_000, 3_000, 4_000, 5_000]
  TROPHY_MILESTONE_INCR = 10_000
  CACHE_VERSION = 4
  EXPIRE_STATISTICS_CACHE_IN = 15.minutes

  def cohort_controlled(cohort)
    display_percentage(cohort[:controlled], cohort[:registered])
  end

  def cohort_uncontrolled(cohort)
    display_percentage(cohort[:uncontrolled], cohort[:registered])
  end

  def cohort_no_bp(cohort)
    display_percentage(cohort[:no_bp], cohort[:registered])
  end

  def diabetes_enabled?
    current_facility.diabetes_enabled?
  end

  def monthly_period_list
    period_list_as_dates(:month, MONTHS_AGO)
  end

  def htn_control_monthly_period_list
    period_list_as_dates(:month, HTN_CONTROL_MONTHS_AGO + 1).reverse.tap(&:pop)
  end

  def display_percentage(numerator, denominator)
    return "0%" if denominator.nil? || denominator.zero? || numerator.nil?
    percentage = (numerator * 100.0) / denominator

    "#{percentage.round(0)}%"
  end

  def last_updated_at
    statistics.dig(:metadata, :last_updated_at)
  end

  def statistics
    @statistics ||=
      Rails.cache.fetch(statistics_cache_key, expires_in: EXPIRE_STATISTICS_CACHE_IN, force: bust_cache?) {
        {
          cohorts: cohort_stats,
          metadata: {
            is_diabetes_enabled: diabetes_enabled?,
            last_updated_at: I18n.l(Time.current),
            formatted_next_date: display_date(Time.current + 1.day),
            today_string: I18n.t(:today_str)
          }
        }
      }
  end

  private

  def cohort_stats
    periods = Period.quarter(Date.current).previous.downto(3)
    CohortService.new(region: current_facility, periods: periods).call
  end

  def statistics_cache_key
    "user_analytics/#{current_facility.id}/dm=#{diabetes_enabled?}/#{CACHE_VERSION}"
  end

  def sum_by_gender(data)
    data.each_with_object({}) do |((_, gender), count), by_gender|
      by_gender[gender] ||= 0
      by_gender[gender] += count
    end
  end
end
