require "rails_helper"
require "sidekiq/testing"
require "dhis2"

describe Dhis2::EthiopiaExporterJob do
  before do
    ENV["DHIS2_DATA_ELEMENTS_FILE"] = "config/data/dhis2/ethiopia-production.yml"
    allow(Flipper).to receive(:enabled?).with(:dhis2_export).and_return(true)
    allow(Flipper).to receive(:enabled?).with(:dhis2_use_ethiopian_calendar).and_return(true)
  end

  describe "#perform" do
    let(:data_elements) { CountryConfig.dhis2_data_elements.fetch(:dhis2_data_elements) }
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

    it "exports HTN metrics required by Ethiopia for a facility for the last n months to DHIS2" do
      facility_identifier = create(:facility_business_identifier)
      total_months = 2
      periods = (Period.current.advance(months: -total_months)..Period.current.previous)
      export_data = []

      periods.each do |period|
        allow_any_instance_of(PatientStates::Hypertension::CumulativeAssignedPatientsQuery).to receive_message_chain(:call, :count).and_return(:htn_cumulative_assigned)
        allow_any_instance_of(PatientStates::Hypertension::ControlledPatientsQuery).to receive_message_chain(:call, :count).and_return(:htn_controlled)
        allow_any_instance_of(PatientStates::Hypertension::UncontrolledPatientsQuery).to receive_message_chain(:call, :count).and_return(:htn_uncontrolled)
        allow_any_instance_of(PatientStates::Hypertension::MissedVisitsPatientsQuery).to receive_message_chain(:call, :count).and_return(:htn_missed_visits)
        allow_any_instance_of(PatientStates::Hypertension::LostToFollowUpPatientsQuery).to receive_message_chain(:call, :count).and_return(:htn_ltfu)
        allow_any_instance_of(PatientStates::Hypertension::DeadPatientsQuery).to receive_message_chain(:call, :count).and_return(:htn_dead)
        allow_any_instance_of(PatientStates::Hypertension::CumulativeRegistrationsQuery).to receive_message_chain(:call, :count).and_return(:htn_cumulative_registrations)
        allow_any_instance_of(PatientStates::Hypertension::MonthlyRegistrationsQuery).to receive_message_chain(:call, :count).and_return(:htn_monthly_registrations)
        allow_any_instance_of(PatientStates::Hypertension::AdjustedAssignedPatientsQuery).to receive_message_chain(:call, :count).and_return(:htn_cumulative_assigned_adjusted)
        facility_data.each do |data_element, value|
          export_data << {
            data_element: data_elements[data_element],
            org_unit: facility_identifier.identifier,
            period: EthiopiaCalendarUtilities.gregorian_month_period_to_ethiopian(period).to_s(:dhis2),
            value: value
          }
        end
      end

      client = double
      data_value_sets = double
      configuration = {}
      allow_any_instance_of(Dhis2::Configuration).to receive(:client_params).and_return(configuration)
      allow(Dhis2::Client).to receive(:new).with(configuration).and_return(client)
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
