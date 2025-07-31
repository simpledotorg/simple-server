module DrRai
  class TitrationIndicator < Indicator
    def datasource(region)
      @query ||= TitrationQuery.new(region).call
      @query[region.name]
    end

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
  end
end
