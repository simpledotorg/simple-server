module Reports
  class RepositoryPresenter < SimpleDelegator
    def self.create(regions, period:, months: Reports::MAX_MONTHS_OF_DATA)
      start_period = period.advance(months: -(months - 1))
      range = Range.new(start_period, period)
      repo = Reports::Repository.new(regions, periods: range)
      new(repo)
    end

    def call(region)
      to_hash(region)
    end

    def to_hash(region)
      slug = region.slug
      {
        adjusted_patient_counts_with_ltfu: adjusted_patients_with_ltfu[slug],
        adjusted_patient_counts: adjusted_patients_without_ltfu[slug],
        controlled_patients_rate: controlled_rates[slug],
        controlled_patients_with_ltfu_rate: controlled_rates(with_ltfu: true)[slug],
        controlled_patients: controlled[slug],
        cumulative_assigned_patients: cumulative_assigned_patients[slug],
        cumulative_registrations: cumulative_registrations[slug],
        cumulative_diabetes_registrations: cumulative_diabetes_registrations[slug],
        earliest_registration_period: earliest_patient_recorded_at_period[slug],
        ltfu_patients_rate: ltfu_rates[slug],
        ltfu_patients: ltfu[slug],
        missed_visits_rate: missed_visits_without_ltfu_rates[slug],
        missed_visits_with_ltfu_rate: missed_visits_with_ltfu_rates[slug],
        missed_visits_with_ltfu: missed_visits_with_ltfu[slug],
        missed_visits: missed_visits[slug],
        period_info: period_info(region),
        registrations: monthly_registrations[slug],
        diabetes_registrations: monthly_diabetes_registrations[slug],
        monthly_diabetes_followups: monthly_diabetes_followups[slug],
        uncontrolled_patients_rate: uncontrolled_rates[slug],
        uncontrolled_patients_with_ltfu_rate: uncontrolled_rates(with_ltfu: true)[slug],
        uncontrolled_patients: uncontrolled[slug],
        visited_without_bp_taken_rates: visited_without_bp_taken_rates[slug],
        visited_without_bp_taken_with_ltfu_rates: visited_without_bp_taken_rates(with_ltfu: true)[slug],
        visited_without_bp_taken: visited_without_bp_taken[slug],
        adjusted_diabetes_patient_counts_with_ltfu: adjusted_diabetes_patients_with_ltfu[slug],
        adjusted_diabetes_patient_counts: adjusted_diabetes_patients_without_ltfu[slug],
        bs_below_200_patients: bs_below_200_patients[slug],
        bs_below_200_rates: bs_below_200_rates[slug],
        bs_below_200_with_ltfu_rates: bs_below_200_rates(with_ltfu: true)[slug],
        bs_below_200_breakdown_rates: diabetes_treatment_outcome_breakdown_rates(:bs_below_200)[slug],
        bs_below_200_breakdown_counts: diabetes_treatment_outcome_breakdown_counts(:bs_below_200)[slug],
        bs_200_to_300_breakdown_rates: diabetes_treatment_outcome_breakdown_rates(:bs_200_to_300)[slug],
        bs_200_to_300_breakdown_counts: diabetes_treatment_outcome_breakdown_counts(:bs_200_to_300)[slug],
        bs_over_300_breakdown_rates: diabetes_treatment_outcome_breakdown_rates(:bs_over_300)[slug],
        bs_over_300_breakdown_counts: diabetes_treatment_outcome_breakdown_counts(:bs_over_300)[slug],
        bs_200_to_300_patients: bs_200_to_300_patients[slug],
        bs_200_to_300_rates: bs_200_to_300_rates[slug],
        bs_200_to_300_with_ltfu_rates: bs_200_to_300_rates(with_ltfu: true)[slug],
        bs_over_300_patients: bs_over_300_patients[slug],
        bs_over_300_rates: bs_over_300_rates[slug],
        bs_over_300_with_ltfu_rates: bs_over_300_rates(with_ltfu: true)[slug],
        diabetes_missed_visits: diabetes_missed_visits[slug],
        diabetes_missed_visits_with_ltfu: diabetes_missed_visits(with_ltfu: true)[slug],
        diabetes_missed_visits_rates: diabetes_missed_visits_rates[slug],
        diabetes_missed_visits_with_ltfu_rates: diabetes_missed_visits_rates(with_ltfu: true)[slug],
        visited_without_bs_taken_rates: visited_without_bs_taken_rates[slug],
        visited_without_bs_taken_with_ltfu_rates: visited_without_bs_taken_rates(with_ltfu: true)[slug],
        visited_without_bs_taken: visited_without_bs_taken[slug]
      }
    end

    def my_facilities_hash(region)
      slug = region.slug
      {
        adjusted_patient_counts: adjusted_patients_without_ltfu[slug],
        controlled_patients_rate: controlled_rates[slug],
        controlled_patients: controlled[slug],
        cumulative_assigned_patients: cumulative_assigned_patients[slug],
        cumulative_registrations: cumulative_registrations[slug],
        facility: region.source,
        facility_size: region.source.facility_size,
        missed_visits_rate: missed_visits_without_ltfu_rates[slug],
        missed_visits: missed_visits[slug],
        period_info: period_info(region),
        uncontrolled_patients_rate: uncontrolled_rates[slug],
        uncontrolled_patients: uncontrolled[slug]
      }
    end
  end
end
