module DrRai
  class StatinsIndicator < Indicator
    attr_reader :region

    def datasource(region)
      @region = region
      @query ||= DrRai::Data::Statin.chartable
      if @query.keys? region.name
        @query[region.name]
      else
        @query[region.slug]
      end
    end

    def display_name
      "Statins"
    end

    def target_type_frontend
      "percent"
    end

    def numerator_key
      :patients_prescribed_statins
    end

    def denominator_key
      :eligible_patients
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
      true
      # @is_supported ||= (datasource(region).present? && true)
    end
  end
end
