module Reports
  class PerformanceScore
    CONTROL_SCORE_WEIGHT = 0.5
    VISITS_SCORE_WEIGHT = 0.3
    REGISTRATIONS_SCORE_WEIGHT = 0.2
    TARGET_REGISTRATION_RATE = 0.1

    def initialize(region:, reports_result:)
      @region = region
      @reports_result = reports_result
    end

    def overall_score
      # max score: 100
      (control_score + visits_score + registrations_score)
    end

    def control_score
      CONTROL_SCORE_WEIGHT * (@reports_result.controlled_patients_rate.values.last || 0)
    end

    def visits_score
      VISITS_SCORE_WEIGHT * visits_rate
    end

    def visits_rate
      100 - (@reports_result.missed_visits_rate.values.last || 0)
    end

    def registrations_score
      REGISTRATIONS_SCORE_WEIGHT * registrations_rate
    end

    def registrations_rate
      registrations = @reports_result.registrations.values.last || 0

      # If the target is zero, return 100% if any registrations occurred
      if target_registrations <= 0
        return registrations > 0 ? 100 : 0
      end

      [100, (registrations / target_registrations) * 100].min
    end

    def target_registrations
      TARGET_REGISTRATION_RATE * (@region.opd_load || 0)
    end
  end
end
