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
      use_who_standard = Flipper.enabled?(:diabetes_who_standard_indicator)
      {
        adjusted_patient_counts_with_ltfu: adjusted_patients_with_ltfu[slug],
        adjusted_patient_counts: adjusted_patients_without_ltfu[slug],
        controlled_patients_rate: controlled_rates[slug],
        controlled_patients_with_ltfu_rate: controlled_rates(with_ltfu: true)[slug],
        controlled_patients: controlled[slug],
        cumulative_assigned_patients: cumulative_assigned_patients[slug],
        cumulative_assigned_diabetes_patients: cumulative_assigned_diabetic_patients[slug],
        cumulative_registrations: cumulative_registrations[slug],
        cumulative_diabetes_registrations: cumulative_diabetes_registrations[slug],
        cumulative_hypertension_and_diabetes_registrations: cumulative_hypertension_and_diabetes_registrations[slug],
        earliest_registration_period: earliest_patient_recorded_at_period[slug],
        ltfu_patients_rate: ltfu_rates[slug],
        ltfu_patients: ltfu[slug],
        diabetes_ltfu_patients: diabetes_ltfu[slug],
        missed_visits_rate: missed_visits_without_ltfu_rates[slug],
        missed_visits_with_ltfu_rate: missed_visits_with_ltfu_rates[slug],
        missed_visits_with_ltfu: missed_visits_with_ltfu[slug],
        missed_visits: missed_visits[slug],
        period_info: period_info(region),
        registrations: monthly_registrations[slug],
        diabetes_registrations: monthly_diabetes_registrations[slug],
        hypertension_and_diabetes_registrations: monthly_hypertension_and_diabetes_registrations[slug],
        monthly_diabetes_followups: monthly_diabetes_followups[slug],
        uncontrolled_patients_rate: uncontrolled_rates[slug],
        uncontrolled_patients_with_ltfu_rate: uncontrolled_rates(with_ltfu: true)[slug],
        uncontrolled_patients: uncontrolled[slug],
        visited_without_bp_taken_rates: visited_without_bp_taken_rates[slug],
        visited_without_bp_taken_with_ltfu_rates: visited_without_bp_taken_rates(with_ltfu: true)[slug],
        visited_without_bp_taken: visited_without_bp_taken[slug],
        adjusted_diabetes_patient_counts_with_ltfu: adjusted_diabetes_patients_with_ltfu[slug],
        adjusted_diabetes_patient_counts: adjusted_diabetes_patients_without_ltfu[slug],
        bs_below_200_patients: use_who_standard ? bs_below_200_patients_fasting_and_hba1c[slug] : bs_below_200_patients[slug],
        bs_below_200_rates: use_who_standard ? bs_below_200_rates_fasting_and_hba1c[slug] : bs_below_200_rates[slug],
        bs_below_200_with_ltfu_rates: use_who_standard ? bs_below_200_rates_fasting_and_hba1c(with_ltfu: true)[slug] : bs_below_200_rates(with_ltfu: true)[slug],
        bs_below_200_breakdown_rates: diabetes_treatment_outcome_breakdown_rates(:bs_below_200)[slug],
        bs_200_to_300_breakdown_rates: diabetes_treatment_outcome_breakdown_rates(:bs_200_to_300)[slug],
        bs_over_300_breakdown_rates: diabetes_treatment_outcome_breakdown_rates(:bs_over_300)[slug],
        bs_over_200_breakdown_rates: diabetes_blood_sugar_over_200_breakdown_rates[slug],
        bs_200_to_300_patients: use_who_standard ? bs_200_to_300_patients_fasting_and_hba1c[slug] : bs_200_to_300_patients[slug],
        bs_200_to_300_rates: use_who_standard ? bs_200_to_300_rates_fasting_and_hba1c[slug] : bs_200_to_300_rates[slug],
        bs_200_to_300_with_ltfu_rates: use_who_standard ? bs_200_to_300_rates_fasting_and_hba1c(with_ltfu: true)[slug] : bs_200_to_300_rates(with_ltfu: true)[slug],
        bs_over_300_patients: use_who_standard ? bs_over_300_patients_fasting_and_hba1c[slug] : bs_over_300_patients[slug],
        bs_over_300_rates: use_who_standard ? bs_over_300_rates_fasting_and_hba1c[slug] : bs_over_300_rates[slug],
        bs_over_300_with_ltfu_rates: use_who_standard ? bs_over_300_rates_fasting_and_hba1c(with_ltfu: true)[slug] : bs_over_300_rates(with_ltfu: true)[slug],
        diabetes_missed_visits: diabetes_missed_visits[slug],
        diabetes_missed_visits_with_ltfu: diabetes_missed_visits(with_ltfu: true)[slug],
        diabetes_missed_visits_rates: diabetes_missed_visits_rates[slug],
        diabetes_missed_visits_with_ltfu_rates: diabetes_missed_visits_rates(with_ltfu: true)[slug],
        visited_without_bs_taken_rates: visited_without_bs_taken_rates[slug],
        visited_without_bs_taken_with_ltfu_rates: visited_without_bs_taken_rates(with_ltfu: true)[slug],
        visited_without_bs_taken: visited_without_bs_taken[slug],
        diabetes_patients_with_bs_taken: diabetes_patients_with_bs_taken[slug],
        diabetes_patients_with_bs_taken_breakdown_rates: diabetes_patients_with_bs_taken_breakdown_rates[slug],
        diabetes_patients_with_bs_taken_breakdown_counts: diabetes_patients_with_bs_taken_breakdown_counts[slug],
        dead: dead[slug],
        diabetes_dead: diabetes_dead[slug],
        under_care: under_care[slug],
        diabetes_under_care: diabetes_under_care[slug],
        overdue_patients: overdue_patients[slug],
        overdue_patients_rates: overdue_patients_rates[slug],
        contactable_overdue_patients: contactable_overdue_patients[slug],
        contactable_overdue_patients_rates: contactable_overdue_patients_rates[slug],
        patients_called: patients_called[slug],
        patients_called_rates: patients_called_rates[slug],
        contactable_patients_called: contactable_patients_called[slug],
        contactable_patients_called_rates: contactable_patients_called_rates[slug],
        patients_called_with_result_agreed_to_visit: patients_called_with_result_agreed_to_visit[slug],
        patients_called_with_result_remind_to_call_later: patients_called_with_result_remind_to_call_later[slug],
        patients_called_with_result_removed_from_list: patients_called_with_result_removed_from_list[slug],
        contactable_patients_called_with_result_agreed_to_visit: contactable_patients_called_with_result_agreed_to_visit[slug],
        contactable_patients_called_with_result_remind_to_call_later: contactable_patients_called_with_result_remind_to_call_later[slug],
        contactable_patients_called_with_result_removed_from_list: contactable_patients_called_with_result_removed_from_list[slug],
        patients_called_with_result_agreed_to_visit_rates: patients_called_with_result_agreed_to_visit_rates[slug],
        patients_called_with_result_remind_to_call_later_rates: patients_called_with_result_remind_to_call_later_rates[slug],
        patients_called_with_result_removed_from_list_rates: patients_called_with_result_removed_from_list_rates[slug],
        contactable_patients_called_with_result_agreed_to_visit_rates: contactable_patients_called_with_result_agreed_to_visit_rates[slug],
        contactable_patients_called_with_result_remind_to_call_later_rates: contactable_patients_called_with_result_remind_to_call_later_rates[slug],
        contactable_patients_called_with_result_removed_from_list_rates: contactable_patients_called_with_result_removed_from_list_rates[slug],
        patients_returned_after_call: patients_returned_after_call[slug],
        patients_returned_after_call_rates: patients_returned_after_call_rates[slug],
        patients_returned_with_result_agreed_to_visit_rates: patients_returned_with_result_agreed_to_visit_rates[slug],
        patients_returned_with_result_remind_to_call_later_rates: patients_returned_with_result_remind_to_call_later_rates[slug],
        patients_returned_with_result_removed_from_list_rates: patients_returned_with_result_removed_from_list_rates[slug],
        contactable_patients_returned_after_call: contactable_patients_returned_after_call[slug],
        contactable_patients_returned_after_call_rates: contactable_patients_returned_after_call_rates[slug],
        contactable_patients_returned_with_result_agreed_to_visit_rates: contactable_patients_returned_with_result_agreed_to_visit_rates[slug],
        contactable_patients_returned_with_result_remind_to_call_later_rates: contactable_patients_returned_with_result_remind_to_call_later_rates[slug],
        contactable_patients_returned_with_result_removed_from_list_rates: contactable_patients_returned_with_result_removed_from_list_rates[slug]
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
