# frozen_string_literal: true

module PeriodSelection
  extend ActiveSupport::Concern

  included do
    MISSED_VISITS_PERIODS = { quarter: 'Quarterly', month: 'Monthly' }.freeze
    REGISTRATIONS_PERIODS = { quarter: 'Quarterly', month: 'Monthly', day: 'Daily' }.freeze

    def set_selected_period
      @selected_period = params[:period].blank? || invalid_period? ? :quarter : params[:period].to_sym
    end

    def invalid_period?
      valid_periods = case action_name.to_sym
      when :missed_visits
        MISSED_VISITS_PERIODS.keys
      when :registrations
        REGISTRATIONS_PERIODS.keys
      end

      !valid_periods.include?(params[:period])
    end
  end
end
