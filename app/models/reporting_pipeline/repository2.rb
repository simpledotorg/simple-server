module ReportingPipeline
  class Repository2
    REGISTRATION_BUFFER_MONTHS = 3

    def initialize(regions, periods:)
      # copy of Reports::Repository#initialize
      @regions = Array(regions)
      @periods = if periods.is_a?(Period)
        Range.new(periods, periods)
      else
        periods
      end
      @period_type = @periods.first.type
      raise ArgumentError, "Quarter periods not supported" if @period_type != :month
    end

    attr_reader :regions
    attr_reader :periods

    def assigned_patients
      PatientStatesPerMonth
        .where(hypertension: "yes", month_date: periods)
        .where_regions(:assigned, regions)
        .group(region_column, :month_date)
    end

    def cumulative_assigned_patients
      assigned_patients
        .where(htn_care_state: [:under_care, :lost_to_follow_up])
        .count
    end

    def adjusted_patients_with_ltfu
      assigned_patients
        .where("months_since_registration >= ?", REGISTRATION_BUFFER_MONTHS)
        .where(htn_care_state: [:under_care, :lost_to_follow_up])
        .count
    end

    def adjusted_patients_without_ltfu
      assigned_patients
        .where("months_since_registration >= ?", REGISTRATION_BUFFER_MONTHS)
        .where(htn_care_state: [:under_care])
        .count
    end

    def earliest_patient_recorded_at
      # TODO: group the AND/OR correctly
      # TODO: is it possible to make this a single query instead of looping?
      regions.each_with_object({}) do |region, hsh|
        pp region, hsh
        hsh[region.slug] =
          PatientStatesPerMonth
            .where(hypertension: "yes")
            .where_regions(:assigned, region)
            .or(PatientStatesPerMonth.where_regions(:registration, region))
            .minimum(:recorded_at)
      end
    end

    def hypertension_follow_ups
      # TODO: the count is per facility at which the BP was taken, not the assigned facility
      # we don't have this information in the table yet, we should include it
      PatientStatesPerMonth
        .where(hypertension: "yes", month_date: periods)
        .where(months_since_visit: 0)
        .where("months_since_registration >= 1")
        .group(region_column, :month_date)
        .count
    end

    def ltfu
      PatientStatesPerMonth
        .where(hypertension: "yes", htn_care_state: :lost_to_follow_up, month_date: periods)
        .group(region_column, :month_date)
        .count
    end

    # treatment control ------------
    # controlled
    # controlled_rates
    # missed_visits
    # missed_visits_rate
    # uncontrolled
    # uncontrolled_rates
    # visited_without_bp_taken

    def treatment_outcomes(htn_care_states, filter)
      PatientStatesPerMonth
        .where(hypertension: "yes", month_date: periods, htn_care_states: htn_care_states)
        .where("months_since_registration >= ?", REGISTRATION_BUFFER_MONTHS)
        .where_regions(:assigned, regions)
        .group(:htn_treatment_outcome_in_last_3_months, region_column, :month_date)
        .count
        .then { |outcomes| nested_hash(outcomes)[filter] }
    end

    def controlled
      treatment_outcomes([:under_care], "controlled")
    end

    def uncontrolled
      treatment_outcomes([:under_care], "uncontrolled")
    end

    def missed_visits_without_ltfu
      treatment_outcomes([:under_care], "missed_visits")
    end

    def visited_no_bp
      treatment_outcomes([:under_care], "visited_no_bp")
    end

    private

    def region_column
      # Assumes that all the region types are the same
      # TODO: validate this assumption
      PatientStatesPerMonth.region_column_name(:assigned, regions.first)
    end

    def nested_hash(flat_hash)
      # Takes the flat hash returned by group(columns), and returns a nested hash
      flat_hash.each_with_object({}) do |(ks, v), h|
        if ks.count == 1
          h[ks.first] = v
        else
          h.deep_merge!({ks.first => nested_hash({ks.drop(1) => v})})
        end
      end
    end

    # list of all methods to replicate
    # ---------------------------------
    # - adjusted_patients
    # bp_measures_by_user
    # - cumulative_assigned_patients
    # earliest_patient_recorded_at
    # hypertension_follow_ups
    # ltfu
    #
    # treatment control ------------
    # controlled
    # controlled_rates
    # missed_visits
    # missed_visits_rate
    # uncontrolled
    # uncontrolled_rates
    # visited_without_bp_taken
    #
    # registrations ----------------
    # complete_monthly_registrations
    # cumulative_registrations
    # monthly_registrations
    # monthly_registrations_by_user

    # questions
    # ------------------------------
    # why do we need to look up by slug in the returned hash
    # if we pass in a parent region, can we avoid a list of regions in the repository?
    # region = Facility.find("d2dae234-f1c7-4ee4-964b-209e1ac9edf2").region
    # repo = Reporting::Repository2.new(region, periods: [Period.month("2021-05-01"), Period.month("2021-06-01")])
    #
  end
end