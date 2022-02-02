module Reports
  class FacilityProgressDimension
    INDICATORS = %i[registrations follow_ups]
    DIAGNOSIS = %i[hypertension diabetes all]
    GENDERS = %i[male female transgender all]

    attr_reader :indicator, :diagnosis, :gender

    def initialize(indicator, diagnosis:, gender:)
      raise ArgumentError, "invalid indicator: #{indicator}" unless indicator.in?(INDICATORS)
      raise ArgumentError, "invalid diagnosis: #{diagnosis}" unless diagnosis.in?(DIAGNOSIS)
      raise ArgumentError, "invalid gender: #{gender}" unless gender.in?(GENDERS)
      if diagnosis == :all && gender != :all
        raise ArgumentError, "Cannot specify a gender and an 'all' diagnosis"
      end
      @indicator = indicator
      @diagnosis = diagnosis
      @gender = gender
    end

    def field
      [:monthly, indicator, diagnosis_code, gender].compact.join("_")
    end

    def diagnosis_code
      case diagnosis
      when :hypertension then :htn
      when :diabetes then :dm
      when :all then nil
      end
    end
  end
end
