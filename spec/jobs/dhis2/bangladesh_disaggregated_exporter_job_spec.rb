require 'rails_helper'
require "sidekiq/testing"
require "dhis2"
Sidekiq::Testing.inline!

describe Dhis2::BangladeshDisaggregatedExporterJob do
  before do
    ENV["DHIS2_DATA_ELEMENTS_FILE"] = "config/data/dhis2/bangladesh-production.yml"
    Flipper.enable(:dhis2_export)
  end

  describe ".perform" do
    it "exports disaggregated HTN metrics for a facility over the last n months to Bangladesh DHIS2" do
      facility_identifier = create(:facility_business_identifier)
      total_months = 2
      periods = Dhis2::Helpers.last_n_month_periods(total_months)
      export_data = []
      data_elements = CountryConfig.dhis2_data_elements.fetch(:disaggregated_dhis2_data_elements)
      category_option_combo_ids = CountryConfig.dhis2_data_elements.fetch(:dhis2_category_option_combo)
      buckets = [15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75]
      facility_data = {
        htn_cumulative_assigned_patients: :htn_cumulative_assigned_patients,
        htn_controlled_patients: :htn_controlled_patients,
        htn_uncontrolled_patients: :htn_uncontrolled_patients,
        htn_patients_who_missed_visits: :htn_patients_who_missed_visits,
        htn_patients_lost_to_follow_up: :htn_patients_lost_to_follow_up,
        htn_dead_patients: :htn_dead_patients,
        htn_cumulative_registered_patients: :htn_cumulative_registered_patients,
        htn_monthly_registered_patients: :htn_monthly_registered_patients,
        htn_cumulative_assigned_patients_adjusted: :htn_cumulative_assigned_patients_adjusted
      }

      periods.each do |period|
        allow_any_instance_of(PatientStates::Hypertension::CumulativeAssignedPatientsQuery).to receive(:call).and_return(:htn_cumulative_assigned_patients)
        allow_any_instance_of(PatientStates::Hypertension::ControlledPatientsQuery).to receive(:call).and_return(:htn_controlled_patients)
        allow_any_instance_of(PatientStates::Hypertension::UncontrolledPatientsQuery).to receive(:call).and_return(:htn_uncontrolled_patients)
        allow_any_instance_of(PatientStates::Hypertension::MissedVisitsPatientsQuery).to receive(:call).and_return(:htn_patients_who_missed_visits)
        allow_any_instance_of(PatientStates::Hypertension::LostToFollowUpPatientsQuery).to receive(:call).and_return(:htn_patients_lost_to_follow_up)
        allow_any_instance_of(PatientStates::Hypertension::DeadPatientsQuery).to receive(:call).and_return(:htn_dead_patients)
        allow_any_instance_of(PatientStates::Hypertension::CumulativeRegistrationsQuery).to receive(:call).and_return(:htn_cumulative_registered_patients)
        allow_any_instance_of(PatientStates::Hypertension::MonthlyRegistrationsQuery).to receive(:call).and_return(:htn_monthly_registered_patients)
        allow_any_instance_of(PatientStates::Hypertension::AdjustedAssignedPatientsQuery).to receive(:call).and_return(:htn_cumulative_assigned_patients_adjusted)

        facility_data.each do |data_element, value|
          allow(Dhis2::Helpers).to receive(:disaggregate_by_gender_age).with(data_element, buckets).and_return({data_element: value})
          category_option_combo_ids.each do |_combo, id|
            export_data << {
              data_element: data_elements[data_element],
              org_unit: facility_identifier.identifier,
              category_option_combo: id,
              period: period.to_s(:dhis2),
              value: 0
            }
          end
        end
      end

      data_value_sets = double
      dhis2_client = double
      allow(Dhis2).to receive(:client).and_return(dhis2_client)
      allow(dhis2_client).to receive(:data_value_sets).and_return(data_value_sets)
      expect(data_value_sets).to receive(:bulk_create).with(data_values: export_data.flatten)

      Sidekiq::Testing.inline! do
        Dhis2::BangladeshDisaggregatedExporterJob.perform_async(
          facility_identifier.id,
          total_months
        )
      end
    end
  end
end
