module DrRai
  class TitrationIndicator < Indicator
    attr_reader :region

    def datasource(region)
      @region = region
      @source ||= DrRai::Data::Titration.chartable
      @source[region.name]
    end

    def display_name
      "Titration"
    end

    def target_type_frontend
      "percent"
    end

    def numerator_key
      :titrated_count
    end

    def denominator_key
      :follow_up_count
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

    def is_supported?(region)
      @is_supported ||= case CountryConfig.current[:name]
      when "Bangladesh"
        region.path.split(".").include?("nhf")
      when "Ethiopia"
        region.path.split(".").none? { |level| level.include?("non_rtsl") }
      when "Sri Lanka"
        region.path.split(".").include?("sri_lanka_organization")
      else
        false
      end
    end
  end
end
