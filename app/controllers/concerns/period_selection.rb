# frozen_string_literal: true

module PeriodSelection
  extend ActiveSupport::Concern

  included do
    PERIODS = { quarter: 'Quarterly', month: 'Monthly', day: 'Daily' }.freeze

    def set_selected_period
      @selected_period = params[:period].blank? ? :quarter : params[:period].to_sym
    end

    def populate_all_periods
      @periods = PERIODS
    end

    def populate_periods(periods)
      @periods = PERIODS.select { |period, _| periods.include?(period) }
    end
  end
end
