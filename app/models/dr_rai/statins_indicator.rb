module DrRai
  class StatinsIndicator < Indicator
    attr_reader :region

    def datasource(region)
      @region = region
      @query ||= StatinsQuery.new(region).call
      @query[region.name]
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

    def percentage
      raise "Unimplemented"
    end

    def is_supported?(region)
      @is_supported ||= (datasource(region).present? && true)
    end
  end
end
