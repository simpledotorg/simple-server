require "rails_helper"

describe Reports::RepositoryPresenter do
  let(:facility) { create(:facility) }
  let(:region) { facility.region }
  let(:presenter) { described_class.create(region, period: Reports.default_period, use_who_standard: use_who_standard) }
  let(:use_who_standard) { nil }

  it "create works" do
    expect(presenter.to_hash(region).keys).to include(:adjusted_patient_counts_with_ltfu, :period_info)
  end

  describe "#to_hash" do
    it "returns required keys" do
      expected_keys = [
        :adjusted_patient_counts_with_ltfu,
        :adjusted_patient_counts,
        :controlled_patients_rate,
        :controlled_patients_with_ltfu_rate,
        :controlled_patients,
        :cumulative_assigned_patients,
        :cumulative_assigned_diabetes_patients,
        :cumulative_registrations,
        :cumulative_diabetes_registrations,
        :cumulative_hypertension_and_diabetes_registrations,
        :earliest_registration_period,
        :ltfu_patients_rate,
        :ltfu_patients,
        :diabetes_ltfu_patients,
        :missed_visits_rate,
        :missed_visits_with_ltfu_rate,
        :missed_visits_with_ltfu,
        :missed_visits,
        :period_info,
        :registrations,
        :diabetes_registrations,
        :hypertension_and_diabetes_registrations,
        :monthly_diabetes_followups,
        :uncontrolled_patients_rate,
        :uncontrolled_patients_with_ltfu_rate,
        :uncontrolled_patients,
        :visited_without_bp_taken_rates,
        :visited_without_bp_taken_with_ltfu_rates,
        :visited_without_bp_taken,
        :adjusted_diabetes_patient_counts_with_ltfu,
        :adjusted_diabetes_patient_counts,
        :bs_below_200_patients,
        :bs_below_200_rates,
        :bs_below_200_with_ltfu_rates,
        :bs_below_200_breakdown_rates,
        :bs_200_to_300_breakdown_rates,
        :bs_over_300_breakdown_rates,
        :bs_over_200_breakdown_rates,
        :bs_200_to_300_patients,
        :bs_200_to_300_rates,
        :bs_200_to_300_with_ltfu_rates,
        :bs_over_300_patients,
        :bs_over_300_rates,
        :bs_over_300_with_ltfu_rates,
        :diabetes_missed_visits,
        :diabetes_missed_visits_with_ltfu,
        :diabetes_missed_visits_rates,
        :diabetes_missed_visits_with_ltfu_rates,
        :visited_without_bs_taken_rates,
        :visited_without_bs_taken_with_ltfu_rates,
        :visited_without_bs_taken,
        :diabetes_patients_with_bs_taken,
        :diabetes_patients_with_bs_taken_breakdown_rates,
        :diabetes_patients_with_bs_taken_breakdown_counts,
        :dead,
        :diabetes_dead,
        :under_care,
        :diabetes_under_care,
        :overdue_patients,
        :overdue_patients_rates,
        :contactable_overdue_patients,
        :contactable_overdue_patients_rates,
        :patients_called,
        :patients_called_rates,
        :contactable_patients_called,
        :contactable_patients_called_rates,
        :patients_called_with_result_agreed_to_visit,
        :patients_called_with_result_remind_to_call_later,
        :patients_called_with_result_removed_from_list,
        :contactable_patients_called_with_result_agreed_to_visit,
        :contactable_patients_called_with_result_remind_to_call_later,
        :contactable_patients_called_with_result_removed_from_list,
        :patients_called_with_result_agreed_to_visit_rates,
        :patients_called_with_result_remind_to_call_later_rates,
        :patients_called_with_result_removed_from_list_rates,
        :contactable_patients_called_with_result_agreed_to_visit_rates,
        :contactable_patients_called_with_result_remind_to_call_later_rates,
        :contactable_patients_called_with_result_removed_from_list_rates,
        :patients_returned_after_call,
        :patients_returned_after_call_rates,
        :patients_returned_with_result_agreed_to_visit_rates,
        :patients_returned_with_result_remind_to_call_later_rates,
        :patients_returned_with_result_removed_from_list_rates,
        :contactable_patients_returned_after_call,
        :contactable_patients_returned_after_call_rates,
        :contactable_patients_returned_with_result_agreed_to_visit_rates,
        :contactable_patients_returned_with_result_remind_to_call_later_rates,
        :contactable_patients_returned_with_result_removed_from_list_rates
      ]
      expect(presenter.to_hash(region).keys).to match_array(expected_keys)
    end

    it "can filter keys" do
      expected_keys = [
        :missed_visits_rate,
        :missed_visits_with_ltfu_rate,
        :missed_visits_with_ltfu,
        :missed_visits,
      ]
      expect(presenter.to_hash(region, keep_only: expected_keys).keys).to match_array(expected_keys)
    end

    it "only filters with an array of symbols" do
      expected_keys = [
        "missed_visits_rate",
        "missed_visits",
      ]
      expect { presenter.to_hash(region, keep_only: expected_keys).keys }.to raise_error("Filter using array of symbols")
    end

    context "when the feature flag for global diabetes indicator is enabled" do
      let(:use_who_standard) { true }

      it "includes fasting and hba1c counts and rates" do
        expect(presenter.schema).to receive(:bs_below_200_patients_fasting_and_hba1c).and_call_original
        expect(presenter.schema).to receive(:bs_below_200_rates_fasting_and_hba1c).twice.and_call_original
        expect(presenter.schema).to receive(:bs_200_to_300_patients_fasting_and_hba1c).and_call_original
        expect(presenter.schema).to receive(:bs_200_to_300_rates_fasting_and_hba1c).twice.and_call_original
        expect(presenter.schema).to receive(:bs_over_300_patients_fasting_and_hba1c).and_call_original
        expect(presenter.schema).to receive(:bs_over_300_rates_fasting_and_hba1c).twice.and_call_original
        presenter.to_hash(region)
      end
    end
  end
end
