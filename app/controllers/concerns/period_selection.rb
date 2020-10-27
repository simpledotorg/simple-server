# frozen_string_literal: true

module PeriodSelection
  extend ActiveSupport::Concern

  PERIODS = {missed_visits: {quarter: "Display quarters", month: "Display months"},
             registrations: {quarter: "Display quarters", month: "Display months", day: "Display days"}}
    .with_indifferent_access
    .freeze

  included do
    def set_selected_period
      @selected_period = params[:period].blank? || invalid_period? ? :quarter : params[:period].to_sym
    end

    def invalid_period?
      valid_periods = PERIODS[action_name].keys

      !valid_periods.include?(params[:period])
    end
  end
end
