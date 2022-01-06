# frozen_string_literal: true

module MonthlyDistrictReport
  module Utils
    def percentage_string(rate)
      rate.to_s + "%"
    end

    def format_period(period)
      period.value.strftime("%b'%y")
    end

    def indicator_string(value, show_as_rate)
      if show_as_rate
        percentage_string(value)
      else
        value
      end
    end
  end
end
