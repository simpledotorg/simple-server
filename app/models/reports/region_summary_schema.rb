module Reports
  class RegionSummarySchema
    include BustCache
    include Memery
    include RegionCaching
    include Percentage

    attr_reader :periods
    attr_reader :period_hash
    attr_reader :regions
    attr_reader :regions_by_type

    delegate :cache, :logger, to: Rails
    delegate :cache_version, to: self

    def self.cache_version
      "2.0"
    end

    def initialize(regions, periods:)
      @regions = regions
      @regions_by_type = regions.group_by { |region| region.region_type }
      @periods = periods
      @period_hash = lambda { |month_date, count| [Period.month(month_date), count] }
    end

    # Returns the earliest patient record for a Region from either assigned or registered patients. Note that this *ignores*
    # the periods that are passed in for the Repository - this is the true 'earliest report date' for a Region.
    memoize def earliest_patient_recorded_at
      region_entries = regions.map { |region| RegionEntry.new(region, __method__) }
      cached_results = cache.fetch_multi(*region_entries, force: bust_cache?) { |region_entry|
        earliest_patient_data_query_v2(region_entry.region)
      }
      cached_results.each_with_object({}) { |(region_entry, time), results| results[region_entry.slug] = time }
    end

    memoize def earliest_patient_recorded_at_period
      earliest_patient_recorded_at.each_with_object({}) { |(slug, time), hsh| hsh[slug] = Period.new(value: time, type: :month) if time }
    end

    # Adjusted patient counts are the patient counts from three months ago (the adjusted period) that
    # are the basis for control rates. These counts DO include lost to follow up.
    memoize def adjusted_patients_with_ltfu
      cumulative_assigned_patients.each_with_object({}) do |(entry, result), results|
        values = periods.each_with_object(Hash.new(0)) { |period, region_result|
          region_result[period] = result[period.adjusted_period]
        }
        results[entry] = values
      end
    end

    memoize def adjusted_diabetes_patients_with_ltfu
      cumulative_assigned_diabetic_patients.each_with_object({}) do |(entry, result), results|
        values = periods.each_with_object(Hash.new(0)) { |period, region_result|
          region_result[period] = result[period.adjusted_period]
        }
        results[entry] = values
      end
    end

    # Adjusted patient counts are the patient counts from three months ago (the adjusted period) that
    # are the basis for control rates. These counts DO NOT include lost to follow up.
    memoize def adjusted_patients_without_ltfu
      values_at("adjusted_patients_under_care")
    end

    memoize def adjusted_diabetes_patients_without_ltfu
      values_at("adjusted_diabetes_patients_under_care")
    end

    alias_method :adjusted_patients, :adjusted_patients_without_ltfu
    alias_method :adjusted_diabetes_patients, :adjusted_diabetes_patients_without_ltfu

    # Return the running total of cumulative assigned patient counts. Note that this *includes* LTFU.
    memoize def cumulative_assigned_patients
      values_at("cumulative_assigned_patients")
    end

    memoize def cumulative_assigned_diabetic_patients
      values_at("cumulative_assigned_diabetic_patients")
    end

    # Returns registration counts per region / period
    memoize def monthly_registrations
      values_at("monthly_registrations")
    end

    memoize def monthly_diabetes_registrations
      values_at("monthly_diabetes_registrations")
    end

    memoize def monthly_hypertension_and_diabetes_registrations
      values_at("monthly_hypertension_and_diabetes_registrations")
    end

    memoize def cumulative_registrations
      values_at("cumulative_registrations")
    end

    memoize def cumulative_diabetes_registrations
      values_at("cumulative_diabetes_registrations")
    end

    memoize def cumulative_hypertension_and_diabetes_registrations
      values_at("cumulative_hypertension_and_diabetes_registrations")
    end

    memoize def ltfu
      values_at("lost_to_follow_up")
    end

    memoize def diabetes_ltfu
      values_at("diabetes_lost_to_follow_up")
    end

    memoize def dead
      values_at("dead")
    end

    memoize def diabetes_dead
      values_at("diabetes_dead")
    end

    memoize def under_care
      values_at("under_care")
    end

    memoize def diabetes_under_care
      values_at("diabetes_under_care")
    end

    memoize def controlled
      values_at("adjusted_controlled_under_care")
    end

    memoize def uncontrolled
      values_at("adjusted_uncontrolled_under_care")
    end

    memoize def total_appts_scheduled
      values_at("total_appts_scheduled")
    end

    memoize def appts_scheduled_0_to_14_days
      values_at("appts_scheduled_0_to_14_days")
    end

    memoize def appts_scheduled_15_to_31_days
      values_at("appts_scheduled_15_to_31_days")
    end

    memoize def appts_scheduled_32_to_62_days
      values_at("appts_scheduled_32_to_62_days")
    end

    memoize def appts_scheduled_more_than_62_days
      values_at("appts_scheduled_more_than_62_days")
    end

    memoize def diabetes_total_appts_scheduled
      values_at("diabetes_total_appts_scheduled")
    end

    memoize def diabetes_appts_scheduled_0_to_14_days
      values_at("diabetes_appts_scheduled_0_to_14_days")
    end

    memoize def diabetes_appts_scheduled_15_to_31_days
      values_at("diabetes_appts_scheduled_15_to_31_days")
    end

    memoize def diabetes_appts_scheduled_32_to_62_days
      values_at("diabetes_appts_scheduled_32_to_62_days")
    end

    memoize def diabetes_appts_scheduled_more_than_62_days
      values_at("diabetes_appts_scheduled_more_than_62_days")
    end

    memoize def overdue_patients
      values_at("overdue_patients")
    end

    memoize def contactable_overdue_patients
      values_at("contactable_overdue_patients")
    end

    memoize def patients_called
      values_at("patients_called")
    end

    memoize def contactable_patients_called
      values_at("contactable_patients_called")
    end

    memoize def patients_called_with_result_agreed_to_visit
      values_at("patients_called_with_result_agreed_to_visit")
    end

    memoize def patients_called_with_result_remind_to_call_later
      values_at("patients_called_with_result_remind_to_call_later")
    end

    memoize def patients_called_with_result_removed_from_list
      values_at("patients_called_with_result_removed_from_list")
    end

    memoize def contactable_patients_called_with_result_agreed_to_visit
      values_at("contactable_patients_called_with_result_agreed_to_visit")
    end

    memoize def contactable_patients_called_with_result_remind_to_call_later
      values_at("contactable_patients_called_with_result_remind_to_call_later")
    end

    memoize def contactable_patients_called_with_result_removed_from_list
      values_at("contactable_patients_called_with_result_removed_from_list")
    end

    memoize def patients_returned_after_call
      values_at("patients_returned_after_call")
    end

    memoize def patients_returned_with_result_agreed_to_visit
      values_at("patients_returned_with_result_agreed_to_visit")
    end

    memoize def patients_returned_with_result_remind_to_call_later
      values_at("patients_returned_with_result_remind_to_call_later")
    end

    memoize def patients_returned_with_result_removed_from_list
      values_at("patients_returned_with_result_removed_from_list")
    end

    memoize def contactable_patients_returned_after_call
      values_at("contactable_patients_returned_after_call")
    end

    memoize def contactable_patients_returned_with_result_agreed_to_visit
      values_at("contactable_patients_returned_with_result_agreed_to_visit")
    end

    memoize def contactable_patients_returned_with_result_remind_to_call_later
      values_at("contactable_patients_returned_with_result_remind_to_call_later")
    end

    memoize def contactable_patients_returned_with_result_removed_from_list
      values_at("contactable_patients_returned_with_result_removed_from_list")
    end

    memoize def ltfu_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(ltfu[slug][period], cumulative_assigned_patients[slug][period])
      end
    end

    memoize def diabetes_ltfu_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(diabetes_ltfu[slug][period], cumulative_assigned_diabetic_patients[slug][period])
      end
    end

    memoize def controlled_rates(with_ltfu: false)
      region_period_cached_query(__method__, with_ltfu: with_ltfu) do |entry|
        treatment_outcome_rates(entry, with_ltfu)[__method__]
      end
    end

    memoize def uncontrolled_rates(with_ltfu: false)
      region_period_cached_query(__method__, with_ltfu: with_ltfu) do |entry|
        treatment_outcome_rates(entry, with_ltfu)[__method__]
      end
    end

    memoize def missed_visits(with_ltfu: false)
      field = with_ltfu ? :adjusted_missed_visit_under_care_with_lost_to_follow_up : :adjusted_missed_visit_under_care
      values_at(field)
    end

    memoize def diabetes_missed_visits(with_ltfu: false)
      field = with_ltfu ? :adjusted_bs_missed_visit_under_care_with_lost_to_follow_up : :adjusted_bs_missed_visit_under_care
      values_at(field)
    end

    memoize def missed_visits_rates(with_ltfu: false)
      region_period_cached_query(__method__, with_ltfu: with_ltfu) do |entry|
        treatment_outcome_rates(entry, with_ltfu)[__method__]
      end
    end

    memoize def diabetes_missed_visits_rates(with_ltfu: false)
      region_period_cached_query(__method__, with_ltfu: with_ltfu) do |entry|
        diabetes_treatment_outcome_rates(entry, with_ltfu)[:missed_visits_rates]
      end
    end

    memoize def overdue_patients_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(overdue_patients[slug][period], under_care[slug][period])
      end
    end

    memoize def patients_called_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(patients_called[slug][period], overdue_patients[slug][period])
      end
    end

    memoize def contactable_overdue_patients_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(contactable_overdue_patients[slug][period], under_care[slug][period])
      end
    end

    memoize def contactable_patients_called_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(contactable_patients_called[slug][period], contactable_overdue_patients[slug][period])
      end
    end

    memoize def patients_called_with_result_agreed_to_visit_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(patients_called_with_result_agreed_to_visit[slug][period], overdue_patients[slug][period])
      end
    end

    memoize def patients_called_with_result_remind_to_call_later_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(patients_called_with_result_remind_to_call_later[slug][period], overdue_patients[slug][period])
      end
    end

    memoize def patients_called_with_result_removed_from_list_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(patients_called_with_result_removed_from_list[slug][period], overdue_patients[slug][period])
      end
    end

    memoize def contactable_patients_called_with_result_agreed_to_visit_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(contactable_patients_called_with_result_agreed_to_visit[slug][period], contactable_overdue_patients[slug][period])
      end
    end

    memoize def contactable_patients_called_with_result_remind_to_call_later_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(contactable_patients_called_with_result_remind_to_call_later[slug][period], contactable_overdue_patients[slug][period])
      end
    end

    memoize def contactable_patients_called_with_result_removed_from_list_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(contactable_patients_called_with_result_removed_from_list[slug][period], contactable_overdue_patients[slug][period])
      end
    end

    memoize def patients_returned_after_call_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(patients_returned_after_call[slug][period], patients_called[slug][period])
      end
    end

    memoize def patients_returned_with_result_agreed_to_visit_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(patients_returned_with_result_agreed_to_visit[slug][period], patients_called[slug][period])
      end
    end

    memoize def patients_returned_with_result_remind_to_call_later_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(patients_returned_with_result_remind_to_call_later[slug][period], patients_called[slug][period])
      end
    end

    memoize def patients_returned_with_result_removed_from_list_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(patients_returned_with_result_removed_from_list[slug][period], patients_called[slug][period])
      end
    end

    memoize def contactable_patients_returned_after_call_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(contactable_patients_returned_after_call[slug][period], contactable_patients_called[slug][period])
      end
    end

    memoize def contactable_patients_returned_with_result_agreed_to_visit_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(contactable_patients_returned_with_result_agreed_to_visit[slug][period], contactable_patients_called[slug][period])
      end
    end

    memoize def contactable_patients_returned_with_result_remind_to_call_later_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(contactable_patients_returned_with_result_remind_to_call_later[slug][period], contactable_patients_called[slug][period])
      end
    end

    memoize def contactable_patients_returned_with_result_removed_from_list_rates
      region_period_cached_query(__method__) do |entry|
        slug, period = entry.slug, entry.period
        percentage(contactable_patients_returned_with_result_removed_from_list[slug][period], contactable_patients_called[slug][period])
      end
    end

    memoize def hypertension_follow_ups(group_by: nil)
      if group_by.nil?
        values_at("monthly_follow_ups")
      else
        group_field = case group_by
                      when /user_id\z/ then :user_id
                      when /gender\z/ then :patient_gender
                      when nil then nil
                      else raise(ArgumentError, "unknown group for follow ups #{group_by}")
        end
        regions.each_with_object({}) do |region, results|
          query = Reports::PatientFollowUp.with_hypertension.where(facility_id: region.facility_ids)
          counts = if group_field
            grouped_counts = query.group(group_field).group_by_period(:month, :month_date, {format: Period.formatter(:month)}).count
            grouped_counts.each_with_object({}) { |(key, count), result|
              group, period = *key
              result[period] ||= {}
              result[period][group] = count
            }
          else
            query.group_by_period(:month, :month_date, {format: Period.formatter(:month)}).select(:patient_id).distinct.count
          end
          results[region.slug] = counts
        end
      end
    end

    memoize def diabetes_follow_ups(group_by: nil)
      if group_by.nil?
        values_at("monthly_diabetes_follow_ups")
      else
        group_field = case group_by
                      when /user_id\z/ then :user_id
                      when /gender\z/ then :patient_gender
                      when nil then nil
                      else raise(ArgumentError, "unknown group for follow ups #{group_by}")
        end
        regions.each_with_object({}) do |region, results|
          query = Reports::PatientFollowUp.with_diabetes.where(facility_id: region.facility_ids)
          counts = if group_field
            grouped_counts = query.group(group_field).group_by_period(:month, :month_date, {format: Period.formatter(:month)}).count
            grouped_counts.each_with_object({}) { |(key, count), result|
              group, period = *key
              result[period] ||= {}
              result[period][group] = count
            }
          else
            query.group_by_period(:month, :month_date, {format: Period.formatter(:month)}).select(:patient_id).distinct.count
          end
          results[region.slug] = counts
        end
      end
    end

    memoize def monthly_diabetes_followups
      values_at("monthly_diabetes_follow_ups")
    end

    memoize def monthly_overdue_calls
      values_at("monthly_overdue_calls")
    end

    alias_method :missed_visits_rate, :missed_visits_rates
    alias_method :missed_visits_without_ltfu, :missed_visits
    alias_method :missed_visits_without_ltfu_rates, :missed_visits_rates

    def missed_visits_with_ltfu
      missed_visits(with_ltfu: true)
    end

    def missed_visits_with_ltfu_rates
      missed_visits_rates(with_ltfu: true)
    end

    def visited_without_bp_taken(with_ltfu: false)
      field = with_ltfu ? :adjusted_visited_no_bp_under_care_with_lost_to_follow_up : :adjusted_visited_no_bp_under_care
      values_at(field)
    end

    memoize def visited_without_bs_taken
      values_at(:adjusted_visited_no_bs_under_care)
    end

    memoize def visited_without_bs_taken_rates(with_ltfu: false)
      region_period_cached_query(__method__, with_ltfu: with_ltfu) do |entry|
        diabetes_treatment_outcome_rates(entry, with_ltfu)[__method__]
      end
    end

    memoize def visited_without_bp_taken_rates(with_ltfu: false)
      region_period_cached_query(__method__, with_ltfu: with_ltfu) do |entry|
        treatment_outcome_rates(entry, with_ltfu)[__method__]
      end
    end

    memoize def appts_scheduled_0_to_14_days_rates
      region_period_cached_query(__method__) do |entry|
        appts_scheduled_rates(entry)[__method__]
      end
    end

    memoize def appts_scheduled_15_to_31_days_rates
      region_period_cached_query(__method__) do |entry|
        appts_scheduled_rates(entry)[__method__]
      end
    end

    memoize def appts_scheduled_32_to_62_days_rates
      region_period_cached_query(__method__) do |entry|
        appts_scheduled_rates(entry)[__method__]
      end
    end

    memoize def appts_scheduled_more_than_62_days_rates
      region_period_cached_query(__method__) do |entry|
        appts_scheduled_rates(entry)[__method__]
      end
    end

    memoize def diabetes_appts_scheduled_0_to_14_days_rates
      region_period_cached_query(__method__) do |entry|
        diabetes_appts_scheduled_rates(entry)[__method__]
      end
    end

    memoize def diabetes_appts_scheduled_15_to_31_days_rates
      region_period_cached_query(__method__) do |entry|
        diabetes_appts_scheduled_rates(entry)[__method__]
      end
    end

    memoize def diabetes_appts_scheduled_32_to_62_days_rates
      region_period_cached_query(__method__) do |entry|
        diabetes_appts_scheduled_rates(entry)[__method__]
      end
    end

    memoize def diabetes_appts_scheduled_more_than_62_days_rates
      region_period_cached_query(__method__) do |entry|
        diabetes_appts_scheduled_rates(entry)[__method__]
      end
    end

    memoize def diabetes_patients_with_bs_taken
      region_period_cached_query(__method__) do |entry|
        adjusted_diabetes_under_care(:bs_below_200)[entry.region.slug][entry.period] +
          adjusted_diabetes_under_care(:bs_200_to_300)[entry.region.slug][entry.period] +
          adjusted_diabetes_under_care(:bs_over_300)[entry.region.slug][entry.period]
      end
    end

    memoize def bs_below_200_patients
      values_at("adjusted_bs_below_200_under_care")
    end

    memoize def bs_200_to_300_patients
      values_at("adjusted_bs_200_to_300_under_care")
    end

    memoize def bs_over_300_patients
      values_at("adjusted_bs_over_300_under_care")
    end

    memoize def bs_below_200_rates(with_ltfu: false)
      region_period_cached_query(__method__, with_ltfu: with_ltfu) do |entry|
        diabetes_treatment_outcome_rates(entry, with_ltfu)[__method__]
      end
    end

    memoize def bs_200_to_300_rates(with_ltfu: false)
      region_period_cached_query(__method__, with_ltfu: with_ltfu) do |entry|
        diabetes_treatment_outcome_rates(entry, with_ltfu)[__method__]
      end
    end

    memoize def bs_over_300_rates(with_ltfu: false)
      region_period_cached_query(__method__, with_ltfu: with_ltfu) do |entry|
        diabetes_treatment_outcome_rates(entry, with_ltfu)[__method__]
      end
    end

    memoize def diabetes_treatment_outcome_breakdown_rates(blood_sugar_risk_state)
      region_period_cached_query(__method__, blood_sugar_risk_state: blood_sugar_risk_state) do |entry|
        rounded_percentages({
          random: adjusted_diabetes_under_care(blood_sugar_risk_state, :random)[entry.region.slug][entry.period],
          post_prandial: adjusted_diabetes_under_care(blood_sugar_risk_state, :post_prandial)[entry.region.slug][entry.period],
          fasting: adjusted_diabetes_under_care(blood_sugar_risk_state, :fasting)[entry.region.slug][entry.period],
          hba1c: adjusted_diabetes_under_care(blood_sugar_risk_state, :hba1c) [entry.region.slug][entry.period]
        })
      end
    end

    memoize def diabetes_blood_sugar_over_200_breakdown_rates
      region_period_cached_query(__method__) do |entry|
        bs_over_200_counts = BloodSugar.blood_sugar_types.keys.map do |blood_sugar_type|
          [blood_sugar_type,
            adjusted_diabetes_under_care(:bs_200_to_300, blood_sugar_type)[entry.region.slug][entry.period] +
              adjusted_diabetes_under_care(:bs_over_300, blood_sugar_type)[entry.region.slug][entry.period]]
        end
        rounded_percentages(bs_over_200_counts.to_h)
      end
    end

    memoize def diabetes_treatment_outcome_breakdown_counts(blood_sugar_risk_state)
      region_period_cached_query(__method__, blood_sugar_risk_state: blood_sugar_risk_state) do |entry|
        {
          random: adjusted_diabetes_under_care(blood_sugar_risk_state, :random)[entry.region.slug][entry.period],
          post_prandial: adjusted_diabetes_under_care(blood_sugar_risk_state, :post_prandial)[entry.region.slug][entry.period],
          fasting: adjusted_diabetes_under_care(blood_sugar_risk_state, :fasting)[entry.region.slug][entry.period],
          hba1c: adjusted_diabetes_under_care(blood_sugar_risk_state, :hba1c) [entry.region.slug][entry.period]
        }
      end
    end

    memoize def diabetes_patients_with_bs_taken_breakdown_counts
      region_period_cached_query(__method__) do |entry|
        bs_taken_breakdown_hash = {}
        Reports::PatientBloodSugar.blood_sugar_risk_states.keys.each do |blood_sugar_risk_state|
          BloodSugar.blood_sugar_types.keys.each do |blood_sugar_type|
            bs_taken_breakdown_hash[[blood_sugar_risk_state.to_sym, blood_sugar_type.to_sym]] =
              adjusted_diabetes_under_care(blood_sugar_risk_state, blood_sugar_type)[entry.region.slug][entry.period]
          end
        end
        bs_taken_breakdown_hash
      end
    end

    memoize def diabetes_patients_with_bs_taken_breakdown_rates
      region_period_cached_query(__method__) do |entry|
        bs_taken_breakdown_hash = {}
        Reports::PatientBloodSugar.blood_sugar_risk_states.keys.each do |blood_sugar_risk_state|
          BloodSugar.blood_sugar_types.keys.each do |blood_sugar_type|
            bs_taken_breakdown_hash[[blood_sugar_risk_state.to_sym, blood_sugar_type.to_sym]] =
              adjusted_diabetes_under_care(blood_sugar_risk_state, blood_sugar_type)[entry.region.slug][entry.period]
          end
        end
        rounded_percentages(bs_taken_breakdown_hash)
      end
    end

    private

    def appts_scheduled_rates(entry)
      rounded_percentages({
        appts_scheduled_0_to_14_days_rates: appts_scheduled_0_to_14_days[entry.region.slug][entry.period],
        appts_scheduled_15_to_31_days_rates: appts_scheduled_15_to_31_days[entry.region.slug][entry.period],
        appts_scheduled_32_to_62_days_rates: appts_scheduled_32_to_62_days[entry.region.slug][entry.period],
        appts_scheduled_more_than_62_days_rates: appts_scheduled_more_than_62_days[entry.region.slug][entry.period]
      })
    end

    def diabetes_appts_scheduled_rates(entry)
      rounded_percentages({
        diabetes_appts_scheduled_0_to_14_days_rates: diabetes_appts_scheduled_0_to_14_days[entry.region.slug][entry.period],
        diabetes_appts_scheduled_15_to_31_days_rates: diabetes_appts_scheduled_15_to_31_days[entry.region.slug][entry.period],
        diabetes_appts_scheduled_32_to_62_days_rates: diabetes_appts_scheduled_32_to_62_days[entry.region.slug][entry.period],
        diabetes_appts_scheduled_more_than_62_days_rates: diabetes_appts_scheduled_more_than_62_days[entry.region.slug][entry.period]
      })
    end

    memoize def treatment_outcome_rates(entry, with_ltfu)
      rounded_percentages({
        visited_without_bp_taken_rates: visited_without_bp_taken(with_ltfu: with_ltfu)[entry.region.slug][entry.period],
        missed_visits_rates: missed_visits(with_ltfu: with_ltfu)[entry.region.slug][entry.period],
        uncontrolled_rates: uncontrolled[entry.region.slug][entry.period],
        controlled_rates: controlled[entry.region.slug][entry.period]
      })
    end

    memoize def diabetes_treatment_outcome_rates(entry, with_ltfu)
      rounded_percentages({
        bs_below_200_rates: adjusted_diabetes_under_care(:bs_below_200)[entry.region.slug][entry.period],
        bs_200_to_300_rates: adjusted_diabetes_under_care(:bs_200_to_300)[entry.region.slug][entry.period],
        bs_over_300_rates: adjusted_diabetes_under_care(:bs_over_300)[entry.region.slug][entry.period],
        missed_visits_rates: diabetes_missed_visits(with_ltfu: with_ltfu)[entry.region.slug][entry.period],
        visited_without_bs_taken_rates: visited_without_bs_taken[entry.region.slug][entry.period]
      })
    end

    memoize def adjusted_diabetes_under_care(blood_sugar_risk_state, blood_sugar_type = nil)
      if blood_sugar_type
        return values_at("adjusted_#{blood_sugar_type}_#{blood_sugar_risk_state}_under_care")
      end
      values_at("adjusted_#{blood_sugar_risk_state}_under_care")
    end

    memoize def earliest_patient_data_query_v2(region)
      if region.diabetes_management_enabled?
        FacilityState.for_region(region)
          .with_htn_or_diabetes_patients
          .minimum(:month_date)
      else
        FacilityState.for_region(region)
          .with_patients
          .minimum(:month_date)
      end
    end

    # Calls RegionSummary for each region_type in our collection of regions -- this is necessary because
    # RegionSummary queries for only type of region at a time.
    memoize def region_summaries
      regions_by_type.each_with_object({}) do |(region_type, regions), result|
        result.merge! RegionSummary.call(regions, range: periods)
      end
    end

    def values_at(field)
      field = field.to_s
      region_summaries.each_with_object({}) { |(slug, period_values), hsh|
        hsh[slug] = period_values.transform_values { |values| values.fetch(field) }.tap { |period_hsh| period_hsh.default = 0 }
      }
    end
  end
end
