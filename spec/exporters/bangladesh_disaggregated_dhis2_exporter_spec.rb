require 'rails_helper'

describe BangladeshDisaggregatedDhis2Exporter do

  describe ".export" do
    it 'should pass the correct config to the main exporter object' do
      expected_arguments = {
        facility_identifiers: FacilityBusinessIdentifier.dhis2_org_unit_id,
        periods: (Period.current.previous.advance(months: -24)..Period.current.previous),
        data_elements_map: CountryConfig.current.fetch(:disaggregated_dhis2_data_elements),
        category_option_combo_ids: CountryConfig.current.fetch(:dhis2_category_option_combo)
      }

      expect(Dhis2Exporter).to receive(:new).with(expected_arguments).and_call_original

      described_class.export
    end

    it 'should call export_disaggregated with a block that generates correct facility-period data for each facility-period combination' do
      facility_identifier = create(:facility_business_identifier)
      period = Period.current

      htn_cumulative_assigned_patients = "htn_cumulative_assigned_patients"
      htn_controlled_patients = "htn_controlled_patients"
      htn_uncontrolled_patients = "htn_uncontrolled_patients"
      htn_patients_who_missed_visits = "htn_patients_who_missed_visits"
      htn_patients_lost_to_follow_up = "htn_patients_lost_to_follow_up"
      htn_dead_patients = "htn_dead_patients"
      htn_cumulative_registered_patients = "htn_cumulative_registered_patients"
      htn_monthly_registered_patients = "htn_monthly_registered_patients"
      htn_cumulative_assigned_patients_adjusted = "htn_cumulative_assigned_patients_adjusted"

      expect_any_instance_of(PatientStates::CumulativeAssignedPatientsQuery).to receive(:call).and_return(htn_cumulative_assigned_patients)
      expect_any_instance_of(PatientStates::ControlledPatientsQuery).to receive(:call).and_return(htn_controlled_patients)
      expect_any_instance_of(PatientStates::UncontrolledPatientsQuery).to receive(:call).and_return(htn_uncontrolled_patients)
      expect_any_instance_of(PatientStates::MissedVisitsPatientsQuery).to receive(:call).and_return(htn_patients_who_missed_visits)
      expect_any_instance_of(PatientStates::LostToFollowUpPatientsQuery).to receive(:call).and_return(htn_patients_lost_to_follow_up)
      expect_any_instance_of(PatientStates::DeadPatientsQuery).to receive(:call).and_return(htn_dead_patients)
      expect_any_instance_of(PatientStates::CumulativeRegistrationsQuery).to receive(:call).and_return(htn_cumulative_registered_patients)
      expect_any_instance_of(PatientStates::MonthlyRegistrationsQuery).to receive(:call).and_return(htn_monthly_registered_patients)
      expect_any_instance_of(PatientStates::CumulativeAssignedPatientsQuery).to receive(:excluding_recent_registrations).and_return(htn_cumulative_assigned_patients_adjusted)

      allow(described_class).to receive(:disaggregated_patient_states) do |value|
        value
      end

      expected_result_from_block = {
        htn_cumulative_assigned_patients: htn_cumulative_assigned_patients,
        htn_controlled_patients: htn_controlled_patients,
        htn_uncontrolled_patients: htn_uncontrolled_patients,
        htn_patients_who_missed_visits: htn_patients_who_missed_visits,
        htn_patients_lost_to_follow_up: htn_patients_lost_to_follow_up,
        htn_dead_patients: htn_dead_patients,
        htn_cumulative_registered_patients: htn_cumulative_registered_patients,
        htn_monthly_registered_patients: htn_monthly_registered_patients,
        htn_cumulative_assigned_patients_adjusted: htn_cumulative_assigned_patients_adjusted
      }

      expect_any_instance_of(Dhis2Exporter).to receive(:export_disaggregated) do |&block|
        result = block.call(facility_identifier, period)
        expect(result).to eq(expected_result_from_block)
      end

      described_class.export
    end
  end

  describe ".disaggregated_patient_states" do
    it 'should take patient states and return their counts disaggregated by gender and age' do
      _patient1 = create(:patient, gender: :male, age: 77)
      _patient2 = create(:patient, gender: :male, age: 64)
      _patient3 = create(:patient, gender: :female, age: 50)
      _patient4 = create(:patient, gender: :transgender, age: 28)

      refresh_views

      patient_states = Reports::PatientState.all
      expected_disaggregated_counts = {
        male_75_plus: 1,
        male_60_64: 1,
        female_50_54: 1,
        transgender_25_29: 1
      }

      expect(described_class.disaggregated_patient_states(patient_states)).to eq(expected_disaggregated_counts)
      expect(described_class.disaggregated_patient_states(patient_states)).not_to have_key(:female_15_19)
    end
  end

  describe '.gender_age_disaggregation' do
    it 'should take patient states and d' do

    end
  end

  describe '.gender_age_range_symbol' do
    it 'should take a gender and age bucket index and return a symbol concatenating the gender and age range' do
      gender = "male"
      age_buckets = (15..75).step(5).to_a
      age_bucket_index = age_buckets.find_index(20) + 1
      expect(described_class.gender_age_range_symbol(gender, age_bucket_index)).to eq(:male_20_24)
    end
  end
end
