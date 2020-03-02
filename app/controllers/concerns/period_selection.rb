# frozen_string_literal: true

module PeriodSelection
  extend ActiveSupport::Concern

  included do
    PERIODS = { missed_visits: { quarter: 'Quarterly', month: 'Monthly' },
                registrations: { quarter: 'Quarterly', month: 'Monthly', day: 'Daily' } }
              .with_indifferent_access
              .freeze

    def set_selected_period
      @selected_period = params[:period].blank? || invalid_period? ? :quarter : params[:period].to_sym
    end

    def invalid_period?
      valid_periods = PERIODS[action_name].keys

      !valid_periods.include?(params[:period])
    end
  end
end
