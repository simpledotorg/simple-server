# frozen_string_literal: true

module CohortPeriodSelection
  extend ActiveSupport::Concern

  included do
    include QuarterHelper

    def selected_cohort_period
      @period = params[:period] == 'month' ? :month : :quarter
      @registration_quarter = sanitize_registration_quarter(params[:registration_quarter])
      @registration_month = sanitize_registration_month(params[:registration_month])
      @registration_year = sanitize_registration_year(params[:registration_year])

      { period: @period,
        registration_quarter: @registration_quarter,
        registration_month: @registration_month,
        registration_year: @registration_year }
    end

    private

    def sanitize_registration_quarter(quarter_param)
      quarter_param.to_i.between?(1, 4) ? quarter_param.to_i : previous_year_and_quarter(Time.current.year, quarter(Time.current)).second
    end

    def sanitize_registration_year(year)
      return year.to_i if year.to_i.positive?

      return (Time.current.beginning_of_month - 1.month).year if @period == :month
      return previous_year_and_quarter(Time.current.year, quarter(Time.current)).first if @period == :quarter
    end

    def sanitize_registration_month(month)
      month.to_i.between?(1, 12) ? month.to_i : (Time.current.beginning_of_month - 1.month).month
    end
  end
end
