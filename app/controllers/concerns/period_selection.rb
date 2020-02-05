# frozen_string_literal: true

module PeriodSelection
  extend ActiveSupport::Concern

  included do
    PERIODS = { quarter: 'Quarterly', month: 'Monthly', day: 'Daily' }

    def set_selected_period
      @selected_period = params[:period].blank? ? :quarter : params[:period].to_sym
    end
  end
end
