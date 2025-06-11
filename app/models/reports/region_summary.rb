module Reports
  # Handles the task of returning summed values from Reports::FacilityState for an array of
  # regions. Must be called with regions all having the same region_type.
  class RegionSummary
    def self.call(regions, range: nil, per: nil)
      new(regions, range: range, per: per).call
    end

    FIELDS = %i[
      adjusted_controlled_under_care
      adjusted_missed_visit_lost_to_follow_up
      adjusted_missed_visit_under_care
      adjusted_patients_under_care
      adjusted_uncontrolled_under_care
      adjusted_visited_no_bp_lost_to_follow_up
      adjusted_visited_no_bp_under_care
      cumulative_assigned_patients
      cumulative_registrations
      cumulative_diabetes_registrations
      cumulative_hypertension_and_diabetes_registrations
      lost_to_follow_up
      diabetes_lost_to_follow_up
      under_care
      diabetes_under_care
      monthly_registrations
      monthly_diabetes_registrations
      monthly_hypertension_and_diabetes_registrations
      monthly_overdue_calls
      monthly_follow_ups
      monthly_diabetes_follow_ups
      total_appts_scheduled
      appts_scheduled_0_to_14_days
      appts_scheduled_15_to_31_days
      appts_scheduled_32_to_62_days
      appts_scheduled_more_than_62_days
      cumulative_assigned_diabetic_patients
      adjusted_diabetes_patients_under_care
      adjusted_bs_below_200_under_care
      adjusted_random_bs_below_200_under_care
      adjusted_post_prandial_bs_below_200_under_care
      adjusted_fasting_bs_below_200_under_care
      adjusted_hba1c_bs_below_200_under_care
      adjusted_visited_no_bs_under_care
      adjusted_bs_missed_visit_under_care
      adjusted_bs_missed_visit_lost_to_follow_up
      adjusted_bs_200_to_300_under_care
      adjusted_random_bs_200_to_300_under_care
      adjusted_post_prandial_bs_200_to_300_under_care
      adjusted_fasting_bs_200_to_300_under_care
      adjusted_hba1c_bs_200_to_300_under_care
      adjusted_bs_over_300_under_care
      adjusted_random_bs_over_300_under_care
      adjusted_post_prandial_bs_over_300_under_care
      adjusted_fasting_bs_over_300_under_care
      adjusted_hba1c_bs_over_300_under_care
      diabetes_total_appts_scheduled
      diabetes_appts_scheduled_0_to_14_days
      diabetes_appts_scheduled_15_to_31_days
      diabetes_appts_scheduled_32_to_62_days
      diabetes_appts_scheduled_more_than_62_days
      dead
      diabetes_dead
      overdue_patients
      contactable_overdue_patients
      patients_called
      contactable_patients_called
      patients_called_with_result_agreed_to_visit
      patients_called_with_result_remind_to_call_later
      patients_called_with_result_removed_from_list
      contactable_patients_called_with_result_agreed_to_visit
      contactable_patients_called_with_result_remind_to_call_later
      contactable_patients_called_with_result_removed_from_list
      patients_returned_after_call
      patients_returned_with_result_agreed_to_visit
      patients_returned_with_result_remind_to_call_later
      patients_returned_with_result_removed_from_list
      contactable_patients_returned_after_call
      contactable_patients_returned_with_result_agreed_to_visit
      contactable_patients_returned_with_result_remind_to_call_later
      contactable_patients_returned_with_result_removed_from_list
    ].sort.freeze

    UNDER_CARE_WITH_LTFU = %i[
      adjusted_missed_visit
      adjusted_visited_no_bp
      adjusted_bs_missed_visit
    ].freeze

    GROUPINGS = %i[
      month
      quarter
    ]

    attr_reader :id_field
    attr_reader :range
    attr_reader :region_type
    attr_reader :regions
    attr_reader :slug_field

    def self.under_care_with_ltfu(field)
      Arel.sql(<<-SQL)
        COALESCE(SUM(#{field}_under_care::int + #{field}_lost_to_follow_up::int), 0) as #{field}_under_care_with_lost_to_follow_up
      SQL
    end

    SUMS = FIELDS.map { |field| Arel.sql("COALESCE(SUM(#{field}::int), 0) as #{field}") }
    CALCULATIONS = UNDER_CARE_WITH_LTFU.map { |field| under_care_with_ltfu(field) }

    def initialize(regions, range: nil, per: nil)
      @range = range
      @grouping = per
      @grouping = :month unless @grouping
      @regions = Array(regions).map(&:region)
      if @regions.map(&:region_type).uniq.size != 1
        raise ArgumentError, "RegionSummary must be called with regions of the same region_type"
      end
      @region_type = @regions.first.region_type
      @id_field = "#{region_type}_region_id"
      @slug_field = region_type == "facility" ? "#{region_type}_region_slug" : "#{region_type}_slug"
      @results = @regions.each_with_object({}) { |region, hsh| hsh[region.slug] = {} }
    end

    def call
      query = for_regions
      query = query.where(month_date: range) if range
      facility_states = query.group(:month_date, slug_field).select("month_date", slug_field, SUMS, CALCULATIONS).order(:month_date)
      facility_states.each { |facility_state|
        @results[facility_state.send(slug_field)][facility_state.period] = facility_state.attributes
      }
      @results unless @grouping
      case @grouping
      when :quarter
        return quarterly(@results)
      else
        return monthly(@results)
      end
    end

    def for_regions
      query = FacilityState
        .where(id_field => regions.map(&:id))

      filter = "cumulative_registrations IS NOT NULL OR cumulative_assigned_patients IS NOT NULL OR monthly_follow_ups IS NOT NULL"
      if regions.any?(&:diabetes_management_enabled?)
        filter += " OR cumulative_diabetes_registrations IS NOT NULL OR cumulative_assigned_diabetic_patients IS NOT NULL OR monthly_diabetes_follow_ups IS NOT NULL"
      end

      query.where(filter)
    end

    # BEGIN Grouping Functions
    #
    # NOTE: For these functions, the result hash must already exist. This means
    # `.call` should have succeeded. Since Ruby is untyped, there is no innate
    # way to enforce this; except to infer on the structure of the hash at runtime.

    def monthly(results_hash)
      raise("Malformed results hash") unless well_formed? results_hash
      results_hash
    end

    def quarterly(results_hash, aggregated_by = :sum)
      raise("Malformed results hash") unless well_formed? results_hash
      case aggregated_by
      when :sum
        output = results_hash.map do |facility, months|
          # NOTE: `months` here is a Period[]
          aggregated = {}

          months.each do |period, stats|
            quarter = period.to_quarter_period
            aggregated[quarter] ||= {}
            stats.each do |attr, val|
              if val.is_a? Numeric
                if aggregated[quarter][attr].nil?
                  aggregated[quarter][attr] = val
                else
                  aggregated[quarter][attr] += val
                end
              else
                # This catches the other case where the data is either a Date or a String
                aggregated[quarter][attr] = val
              end
            end
          end

          [
            facility,
            aggregated
          ]
        end.to_h
        output
      when :average
        raise("Unimplemented")
      else
        raise("Unimplemented")
      end
    end

    def well_formed?(results_hash)
      # This is an effect of an old code base. Ideally, this is type-checking.
      # But since we are building on a righ without type-checking, we have to
      # manually do these checks.
      results_hash.all? do |facility, period_data|
        facility.is_a?(String) &&
          period_data.all? do |period, _|
            period.is_a? Period
          end
      end
    end

    # END Grouping Functions
  end
end
