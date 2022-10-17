module Reports
  class FacilityProgressDimension
    INDICATORS = %i[registrations follow_ups]
    DIAGNOSIS = %i[hypertension_and_diabetes hypertension diabetes all]
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

    def field_v1
      [:monthly, indicator, diagnosis_code_v1, gender_code_v1].compact.join("_")
    end

    def diagnosis_code
      case diagnosis
      when :hypertension then :htn
      when :diabetes then :dm
      when :all then nil
      end
    end

    def diagnosis_code_v1
      case diagnosis
      when :hypertension_and_diabetes then :htn_and_dm
      when :hypertension then :htn_only
      when :diabetes then :dm_only
      when :all then :htn_or_dm
      end
    end

    def gender_code_v1
      if diagnosis == :all || gender == :all
        nil
      else
        gender
      end
    end
  end
end
