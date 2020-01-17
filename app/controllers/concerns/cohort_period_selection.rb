# frozen_string_literal: true

module CohortPeriodSelection
  extend ActiveSupport::Concern

  included do
    def selected_cohort_period
      period = params[:period] == 'month' ? :month : :quarter
      quarter = params[:quarter] ? params[:quarter].to_i : quarter(Time.current)
      month = params[:month] ? params[:month].to_i : Time.current.month
      year = params[:year] ? params[:year].to_i : Time.current.year

      { period: period, quarter: quarter, month: month, year: year }
    end
  end
end
