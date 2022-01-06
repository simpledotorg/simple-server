# frozen_string_literal: true

module Reports
  class PerformanceScore
    IDEAL_CONTROL_RATE = 0.7
    IDEAL_VISITS_RATE = 0.8
    IDEAL_REGISTRATIONS_RATE = 1.0

    CONTROL_SCORE_WEIGHT = 0.5
    VISITS_SCORE_WEIGHT = 0.3
    REGISTRATIONS_SCORE_WEIGHT = 0.2

    def initialize(region:, reports_result:, period:)
      @region = region
      @reports_result = reports_result
      @period = period
    end

    def letter_grade
      if overall_score > 75
        "A"
      elsif overall_score > 50
        "B"
      elsif overall_score > 25
        "C"
      else
        "D"
      end
    end

    def overall_score
      # max score: 100
      @overall_score ||= (control_score + visits_score + registrations_score)
    end

    def control_score
      CONTROL_SCORE_WEIGHT * adjusted_control_rate
    end

    def adjusted_control_rate
      [100, control_rate / IDEAL_CONTROL_RATE].min
    end

    def control_rate
      @reports_result.controlled_patients_rate[@period] || 0
    end

    def visits_score
      VISITS_SCORE_WEIGHT * adjusted_visits_rate
    end

    def adjusted_visits_rate
      [100, visits_rate / IDEAL_VISITS_RATE].min
    end

    def visits_rate
      100 - (@reports_result.missed_visits_rate[@period] || 0)
    end

    def registrations_score
      REGISTRATIONS_SCORE_WEIGHT * adjusted_registrations_rate
    end

    def adjusted_registrations_rate
      [100, registrations_rate / IDEAL_REGISTRATIONS_RATE].min
    end

    def registrations_rate
      # If opd load is 0, return 100% if any registrations occurred
      if (@region.opd_load || 0) <= 0
        return registrations > 0 ? 100 : 0
      end

      registrations / @region.opd_load.to_f * 100.0
    end

    def registrations
      @reports_result.registrations[@period] || 0
    end
  end
end
