# frozen_string_literal: true

module PeriodSelection
  extend ActiveSupport::Concern

  included do
    MISSED_VISITS_PERIODS = { quarter: 'Quarterly', month: 'Monthly' }.freeze
    REGISTRATIONS_PERIODS = { quarter: 'Quarterly', month: 'Monthly', day: 'Daily' }.freeze

    def set_selected_period
      @selected_period = params[:period].blank? ? :quarter : params[:period].to_sym
    end
  end
end
