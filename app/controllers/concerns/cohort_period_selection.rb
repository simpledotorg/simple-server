# frozen_string_literal: true

module CohortPeriodSelection
  extend ActiveSupport::Concern

  included do
    include QuarterHelper

    def selected_cohort_period
      @period = params[:period] == 'month' ? :month : :quarter
      @quarter = sanitize_quarter(params[:quarter])
      @month = sanitize_month(params[:month])
      @year = sanitize_year(params[:year])

      { period: @period, quarter: @quarter, month: @month, year: @year }
    end

    private

    def sanitize_quarter(quarter_param)
      quarter_param.to_i.between?(1, 4) ? quarter_param.to_i : quarter(Time.current)
    end

    def sanitize_year(year)
      year.to_i.positive? ? year.to_i : Time.current.year
    end

    def sanitize_month(month)
      month.to_i.between?(1, 12) ? month.to_i : Time.current.month
    end
  end
end
