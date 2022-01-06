# frozen_string_literal: true

module OneOff
  class FixKokaHcBps
    def self.call
      new.call
    end

    attr_reader :country, :facility

    def initialize
      @country = CountryConfig.current[:abbreviation]
      @facility = Facility.find_by(name: "Koka Health Center")
    end

    def call
      unless country == "ET"
        Rails.logger.info "FixKokaHcBps can only be executed in Ethiopia. Quitting."
        return
      end

      unless facility.present?
        Rails.logger.info "Koka HC is missing. Quitting."
        return
      end

      eligible_bps.each do |bp|
        update_bp(bp)
        update_patient(bp.patient)
      end
    end

    private

    def eligible_bps
      @bps ||= facility.blood_pressures.where("recorded_at > '2012-01-01' AND recorded_at < '2014-01-01'").includes(:patient)
    end

    def update_bp(bp)
      ethiopian_date = bp.recorded_at
      gregorian_date = EthiopiaCalendarUtilities.ethiopian_to_gregorian(
        ethiopian_date.year,
        ethiopian_date.month,
        ethiopian_date.day
      )

      bp.update!(recorded_at: gregorian_date)
    end

    def update_patient(patient)
      earliest_bp_date = patient.blood_pressures.minimum(:recorded_at)

      patient.update!(recorded_at: earliest_bp_date)
    end
  end
end
