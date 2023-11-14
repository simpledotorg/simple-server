require "rails_helper"
require "sidekiq/testing"
require "dhis2"
Sidekiq::Testing.inline!

describe Dhis2::BangladeshDisaggregatedExporterJob do
  before do
    ENV["DHIS2_DATA_ELEMENTS_FILE"] = "config/data/dhis2/bangladesh-production.yml"
    allow(Flipper).to receive(:enabled?).with(:dhis2_export).and_return(true)
    allow(Flipper).to receive(:enabled?).with(:dhis2_use_ethiopian_calendar).and_return(false)
  end

  describe ".perform" do
    let(:data_elements) { CountryConfig.dhis2_data_elements.fetch(:disaggregated_dhis2_data_elements) }
    let(:category_option_combo_ids) { CountryConfig.dhis2_data_elements.fetch(:dhis2_category_option_combo) }
    let(:buckets) { [15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75] }
    let(:facility_data) {
      {
        htn_cumulative_assigned: :htn_cumulative_assigned,
        htn_controlled: :htn_controlled,
        htn_uncontrolled: :htn_uncontrolled,
        htn_missed_visits: :htn_missed_visits,
        htn_ltfu: :htn_ltfu,
        htn_dead: :htn_dead,
        htn_cumulative_registrations: :htn_cumulative_registrations,
        htn_monthly_registrations: :htn_monthly_registrations,
        htn_cumulative_assigned_adjusted: :htn_cumulative_assigned_adjusted
      }
    }

    it "exports disaggregated HTN metrics for a facility over the last n months to Bangladesh DHIS2" do
      facility_identifier = create(:facility_business_identifier)
      total_months = 2
      periods = (Period.current.advance(months: -total_months)..Period.current.previous)
      export_data = []

      periods.each do |period|
        allow_any_instance_of(PatientStates::Hypertension::CumulativeAssignedPatientsQuery).to receive(:call).and_return(:htn_cumulative_assigned)
        allow_any_instance_of(PatientStates::Hypertension::ControlledPatientsQuery).to receive(:call).and_return(:htn_controlled)
        allow_any_instance_of(PatientStates::Hypertension::UncontrolledPatientsQuery).to receive(:call).and_return(:htn_uncontrolled)
        allow_any_instance_of(PatientStates::Hypertension::MissedVisitsPatientsQuery).to receive(:call).and_return(:htn_missed_visits)
        allow_any_instance_of(PatientStates::Hypertension::LostToFollowUpPatientsQuery).to receive(:call).and_return(:htn_ltfu)
        allow_any_instance_of(PatientStates::Hypertension::DeadPatientsQuery).to receive(:call).and_return(:htn_dead)
        allow_any_instance_of(PatientStates::Hypertension::CumulativeRegistrationsQuery).to receive(:call).and_return(:htn_cumulative_registrations)
        allow_any_instance_of(PatientStates::Hypertension::MonthlyRegistrationsQuery).to receive(:call).and_return(:htn_monthly_registrations)
        allow_any_instance_of(PatientStates::Hypertension::AdjustedAssignedPatientsQuery).to receive(:call).and_return(:htn_cumulative_assigned_adjusted)

        facility_data.each do |data_element, value|
          expect_any_instance_of(described_class).to receive(:disaggregate_by_gender_age).with(data_element, buckets).and_return({data_element: value})
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

      client = double
      data_value_sets = double
      allow_any_instance_of(Dhis2::Configuration).to receive(:client_params).and_return({})
      allow(Dhis2::Client).to receive(:new).with({}).and_return(client)
      allow(client).to receive(:data_value_sets).and_return(data_value_sets)
      expect(data_value_sets).to receive(:bulk_create).with(data_values: export_data.flatten)

      Sidekiq::Testing.inline! do
        described_class.perform_async(
          facility_identifier.id,
          total_months
        )
      end
    end
  end
end
