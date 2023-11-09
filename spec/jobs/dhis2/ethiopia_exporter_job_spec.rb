require "rails_helper"
require "sidekiq/testing"
require "dhis2"
Sidekiq::Testing.inline!

describe Dhis2::EthiopiaExporterJob do
  before do
    ENV["DHIS2_PASSWORD"] = "test_password"
    ENV["DHIS2_URL"] = "http://foo.bar"
    ENV["DHIS2_USERNAME"] = "test_user"
    ENV["DHIS2_DATA_ELEMENTS_FILE"] = "config/data/dhis2/ethiopia-production.yml"
    Flipper.enable(:dhis2_export)
    Flipper.enable(:dhis2_use_ethiopian_calendar)
  end

  describe ".perform" do
    let(:data_elements) { CountryConfig.dhis2_data_elements.fetch(:dhis2_data_elements) }
    let(:facility_data) {
      {
        htn_cumulative_assigned: :htn_cumulative_assigned,
        htn_cumulative_assigned_adjusted: :htn_cumulative_assigned_adjusted,
        htn_controlled: :htn_controlled,
        htn_uncontrolled: :htn_uncontrolled,
        htn_missed_visits: :htn_missed_visits,
        htn_ltfu: :htn_ltfu,
        htn_dead: :htn_dead,
        htn_cumulative_registrations: :htn_cumulative_registrations,
        htn_monthly_registrations: :htn_monthly_registrations
      }
    }

    it "exports metrics required by Ethiopia for the given facility for the last given number of months to DHIS2" do
      facility_identifier = create(:facility_business_identifier)
      total_months = 1
      periods = (Period.current.advance(months: -total_months)..Period.current.previous)
      export_data = []

      periods.each do |period|
        expect_any_instance_of(PatientStates::Hypertension::CumulativeAssignedPatientsQuery).to receive_message_chain(:call, :count).and_return(:htn_cumulative_assigned)
        expect_any_instance_of(PatientStates::Hypertension::AdjustedAssignedPatientsQuery).to receive_message_chain(:call, :count).and_return(:htn_cumulative_assigned_adjusted)
        expect_any_instance_of(PatientStates::Hypertension::ControlledPatientsQuery).to receive_message_chain(:call, :count).and_return(:htn_controlled)
        expect_any_instance_of(PatientStates::Hypertension::UncontrolledPatientsQuery).to receive_message_chain(:call, :count).and_return(:htn_uncontrolled)
        expect_any_instance_of(PatientStates::Hypertension::MissedVisitsPatientsQuery).to receive_message_chain(:call, :count).and_return(:htn_missed_visits)
        expect_any_instance_of(PatientStates::Hypertension::LostToFollowUpPatientsQuery).to receive_message_chain(:call, :count).and_return(:htn_ltfu)
        expect_any_instance_of(PatientStates::Hypertension::DeadPatientsQuery).to receive_message_chain(:call, :count).and_return(:htn_dead)
        expect_any_instance_of(PatientStates::Hypertension::CumulativeRegistrationsQuery).to receive_message_chain(:call, :count).and_return(:htn_cumulative_registrations)
        expect_any_instance_of(PatientStates::Hypertension::MonthlyRegistrationsQuery).to receive_message_chain(:call, :count).and_return(:htn_monthly_registrations)
        facility_data.each do |data_element, value|
          export_data << {
            data_element: data_elements[data_element],
            org_unit: facility_identifier.identifier,
            period: EthiopiaCalendarUtilities.gregorian_month_period_to_ethiopian(period).to_s(:dhis2),
            value: value
          }
        end
      end

      data_value_sets = double
      allow_any_instance_of(Dhis2::Client).to receive(:data_value_sets).and_return(data_value_sets)
      expect(data_value_sets).to receive(:bulk_create).with(data_values: export_data.flatten)

      Sidekiq::Testing.inline! do
        Dhis2::EthiopiaExporterJob.perform_async(
          facility_identifier.id,
          total_months
        )
      end
    end
  end
end
