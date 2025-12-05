module DrRai
  class BpFudgingIndicator < Indicator
    attr_reader :region

    def datasource(region)
      @region = region
      @source ||= DrRai::Data::BpFudging.chartable
      @source[region.name]
    end

    def display_name
      "BP Fudging"
    end

    def target_type_frontend
      "boolean"
    end

    def numerator_key all: nil
      :numerator
    end

    def denominator_key all: nil
      :denominator
    end

    def action_passive
      "fudged"
    end

    def action_active
      "Fudge"
    end

    def unit
      "bps"
    end

    def is_supported?(region)
      true
    end
  end
end
