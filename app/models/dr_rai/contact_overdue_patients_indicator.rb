module DrRai
  class ContactOverduePatientsIndicator < Indicator
    def display_name
      "Contact overdue patients"
    end

    def numerator(region, the_period = period)
      numerators(region)[the_period]
    end

    def denominator(region, the_period = period)
      denominators(region)[the_period]
    end

    def numerators(region)
      quarterlies(region).map do |t, data|
        [t, data[numerator_key]]
      end.to_h
    end

    def denominators(region)
      quarterlies(region).map do |t, data|
        [t, data[denominator_key]]
      end.to_h
    end

    def target_type
      "DrRai::PercentageTarget"
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
  end
end
