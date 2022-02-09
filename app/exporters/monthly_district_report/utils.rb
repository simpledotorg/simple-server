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

    def percentage(numerator, denominator)
      return 0 if numerator.nil? || denominator.nil? || denominator == 0 || numerator == 0
      ((numerator.to_f / denominator) * 100).round(0)
    end
  end
end
