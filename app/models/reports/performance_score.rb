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

    def call
      overall_score
    end

    def overall_score
      # max score: 100
      (control_score + visits_score + registrations_score)
    end

    def control_score
      CONTROL_SCORE_WEIGHT * @result.controlled_patients_rate.values.last
    end

    def visits_score
      visits_rate = 100 - @result.missed_visits_rate.values.last

      VISITS_SCORE_WEIGHT * visits_rate
    end

    def registrations_score
      REGISTRATIONS_SCORE_WEIGHT * registration_rate
    end

    def registration_rate
      monthly_registrations = @result.registrations.values.last
      target_registrations = @region.opd_load * TARGET_REGISTRATION_RATE

      (monthly_registrations / target_registrations) * 100
    end
  end
end
