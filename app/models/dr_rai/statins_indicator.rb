module DrRai
  class StatinsIndicator < Indicator
    def datasource(region)
      quarterlies(region)
    end

    def display_name
      "Statins"
    end

    def target_type_frontend
      "percent"
    end

    def numerator_key all: nil
      "adjusted_dm_patients_40_and_above_with_statins"
    end

    def denominator_key all: nil
      "adjusted_dm_patients_40_and_above_under_care"
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

    def is_supported?(region)
      datasource(region).present?
    end
  end
end
