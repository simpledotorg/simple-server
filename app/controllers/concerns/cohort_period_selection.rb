# frozen_string_literal: true

module CohortPeriodSelection
  extend ActiveSupport::Concern

  included do
    include QuarterHelper

    def set_selected_cohort_period
      cohort_period = params[:cohort_period] == "month" ? :month : :quarter
      @selected_cohort_period =
        {cohort_period: cohort_period,
         registration_quarter: sanitize_registration_quarter(params[:registration_quarter]),
         registration_month: sanitize_registration_month(params[:registration_month]),
         registration_year: sanitize_registration_year(params[:registration_year], cohort_period)}
    end

    private

    def sanitize_registration_quarter(quarter_param)
      return quarter_param.to_i if quarter_param.to_i.between?(1, 4)

      previous_year_and_quarter(Time.current.year, quarter(Time.current)).second
    end

    def sanitize_registration_year(year, cohort_period)
      return year.to_i if year.to_i.positive?
      return (Time.current.beginning_of_month - 1.month).year if cohort_period == :month

      previous_year_and_quarter(Time.current.year, quarter(Time.current)).first
    end

    def sanitize_registration_month(month)
      month.to_i.between?(1, 12) ? month.to_i : (Time.current.beginning_of_month - 1.month).month
    end
  end
end
