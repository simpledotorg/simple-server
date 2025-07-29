module DrRai
  class TitrationIndicator < Indicator
    def display_name
      "Titration"
    end

    def target_type_frontend
      "percent"
    end

    def numerator_key
      "titrated"
    end

    def denominator_key
      "patients"
    end

    def action_passive
      "titrated"
    end

    def action_active
      "Titrate"
    end

    def unit
      "patients"
    end

    def denominator(region, the_period = period)
      100
    end

    def numerator(region, the_period = period)
      89
    end
  end
end
