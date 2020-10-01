module Reports
  class PerformanceScore
    CONTROL_SCORE_WEIGHT = 0.5
    VISITS_SCORE_WEIGHT = 0.3
    REGISTRATIONS_SCORE_WEIGHT = 0.2
    TARGET_REGISTRATION_RATE = 0.1

    def initialize(region:, result:)
      @region = region
      @result = result
    end

    def overall_score
      # max score: 100
      (control_score + visits_score + registrations_score)
    end

    def control_score
      CONTROL_SCORE_WEIGHT * @result.controlled_patients_rate.values.last
    end

    def visits_score
      VISITS_SCORE_WEIGHT * visits_rate
    end

    def visits_rate
      100 - @result.missed_visits_rate.values.last
    end

    def registrations_score
      REGISTRATIONS_SCORE_WEIGHT * registrations_rate
    end

    def registrations_rate
      registrations = @result.registrations.values.last

      # If the target is zero, return 100% if any registrations occurred
      if target_registrations <= 0
        return registrations > 0 ? 100 : 0
      end

      (registrations / target_registrations) * 100
    end

    def target_registrations
      @region.opd_load * TARGET_REGISTRATION_RATE
    end
  end
end
