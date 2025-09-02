module DrRai
  class ContactOverduePatientsIndicator < Indicator
    def datasource(region)
      quarterlies(region)
    end

    def display_name
      "Contact overdue patients"
    end

    def target_type_frontend
      "percent"
    end

    def numerator_key
      "contactable_patients_called"
    end

    def denominator_key
      "overdue_patients"
    end

    def unit
      "overdue patients"
    end

    def action_passive
      "called"
    end

    def action_active
      "Call"
    end

    def is_supported?(region)
      true
    end
  end
end
