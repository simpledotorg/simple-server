module DrRai
  class StatinsIndicator < Indicator
    attr_reader :region

    def datasource(region)
      nil
    end

    def display_name
      "Statins"
    end

    def target_type_frontend
      "percent"
    end

    def numerator_key
      raise "Undecided"
    end

    def denominator_key
      raise "Undecided"
    end

    def unit
      "patients"
    end

    def action_passive
      "prescribed statins"
    end

    def action_active
      "Prescribe statins for"
    end
  end
end
