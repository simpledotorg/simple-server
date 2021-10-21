module Reports
  class RepositoryPresenter < SimpleDelegator
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
        earliest_registration_period: earliest_patient_recorded_at_period[slug],
        ltfu_patients_rate: ltfu_rates[slug],
        ltfu_patients: ltfu[slug],
        missed_visits_rate: missed_visits_without_ltfu_rates[slug],
        missed_visits_with_ltfu_rate: missed_visits_with_ltfu_rates[slug],
        missed_visits_with_ltfu: missed_visits_with_ltfu[slug],
        missed_visits: missed_visits[slug],
        period_info: period_info(region),
        registrations: monthly_registrations[slug],
        uncontrolled_patients_rate: uncontrolled_rates[slug],
        uncontrolled_patients_with_ltfu_rate: uncontrolled_rates(with_ltfu: true)[slug],
        uncontrolled_patients: uncontrolled[slug],
        visited_without_bp_taken_rates: visited_without_bp_taken_rates[slug],
        visited_without_bp_taken_with_ltfu_rates: visited_without_bp_taken_rates(with_ltfu: true)[slug],
        visited_without_bp_taken: visited_without_bp_taken[slug],
      }
    end

  end
end