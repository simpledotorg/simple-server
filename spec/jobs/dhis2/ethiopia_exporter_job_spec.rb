require "rails_helper"
require "dhis2"

describe Dhis2::EthiopiaExporterJob do
  let(:configuration) { {} }
  let(:client) { double }
  let(:data_value_sets) { double }
  let(:attribute_option_combo_id) { CountryConfig.dhis2_data_elements.fetch(:dhis2_attribute_option) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("DHIS2_DATA_ELEMENTS_FILE").and_return("config/data/dhis2/ethiopia-production.yml")
    allow(Flipper).to receive(:enabled?).with(:dhis2_export).and_return(true)
    allow(Flipper).to receive(:enabled?).with(:dhis2_use_ethiopian_calendar).and_return(true)
    allow_any_instance_of(Dhis2::Configuration).to receive(:client_params).and_return(configuration)
    allow(Dhis2::Client).to receive(:new).with(configuration).and_return(client)
  end

  describe "#perform" do
    let(:data_elements) { CountryConfig.dhis2_data_elements.fetch(:dhis2_data_elements) }
    let(:facility_data) {
      {
        htn_enrolled_under_care: {category_option_key: "dhis2_age_gender_category_elements", values: gender_age_count},
        htn_enrolled_under_care_treatment: {category_option_key: "dhis2_treatment_category_elements", values: treatment_type_count},
        htn_by_enrollment_time: {category_option_key: "dhis2_enrollment_time_category_elements", values: enrollment_data_count},
        htn_cohort_registered: {category_option_key: "dhis2_cohort_registered_category_elements", values: cohort_registered_data_count},
        htn_cohort_outcome: {category_option_key: "dhis2_cohort_category_elements", values: cohort_data_count}
      }
    }
    let(:gender_age_data) { {["female", 33] => 74, ["male", 96] => 72} }
    let(:gender_age_count) {
      {
        "18_29_male" => 0,
        "18_29_female" => 0,
        "30_39_male" => 0,
        "30_39_female" => 74,
        "40_69_male" => 0,
        "40_69_female" => 0,
        "70_200_male" => 72,
        "70_200_female" => 0
      }
    }
    let(:treatment_type_count) { {"lsm" => 0, "pharma_mangement" => 0} }
    let(:enrollment_data_count) { {"newly_enrolled" => 0, "previously_enrolled" => 0} }
    let(:cohort_registered_data_count) { {"default" => 0} }
    let(:cohort_data_count) { {"controlled" => 0, "uncontrolled" => 0, "lost_to_follow_up" => 0, "dead" => 0, "transferred_out" => 0} }
    let(:patients) { Reports::PatientState.where(hypertension: "yes") }

    it "exports HTN metrics required by Ethiopia for a facility for the last n months to DHIS2" do
      facility_identifier = create(:facility_business_identifier)
      total_months = 2
      periods = (Period.current.advance(months: -total_months)..Period.current.previous)
      export_data = []
      periods.each do |period|
        facility_data.each do |data_element, value|
          if value[:category_option_key]
            CountryConfig.dhis2_data_elements.fetch((value[:category_option_key])).each do |category_key, id|
              export_data << {
                data_element: data_elements[data_element],
                org_unit: facility_identifier.identifier,
                category_option_combo: id,
                period: EthiopiaCalendarUtilities.gregorian_month_period_to_ethiopian(period).to_s(:dhis2),
                attribute_option_combo: attribute_option_combo_id,
                value: value[:values][category_key]
              }
            end
          else
            export_data << {
              data_element: data_elements[data_element],
              org_unit: facility_identifier.identifier,
              period: EthiopiaCalendarUtilities.gregorian_month_period_to_ethiopian(period).to_s(:dhis2),
              attribute_option_combo: attribute_option_combo_id,
              value: value[:value]
            }
          end
        end
      end
      Reports::PatientState.refresh
      expect_any_instance_of(PatientStates::Hypertension::RegistrationsUnderCareGenderAgeAggregatedQuery).to receive_message_chain(:call).and_return(gender_age_data)
      expect_any_instance_of(PatientStates::Hypertension::RegistrationsUnderCareQuery).to receive_message_chain(:call).and_return(patients.to_a)
      expect_any_instance_of(PatientStates::Hypertension::CumulativeRegistrationsQuery).to receive_message_chain(:call).and_return(patients.to_a)
      expect_any_instance_of(PatientStates::Hypertension::RegistrationsForMonthsQuery).to receive_message_chain(:call).and_return(patients.to_a)
      allow(client).to receive(:data_value_sets).and_return(data_value_sets)
      expect(data_value_sets).to receive(:bulk_create).with(data_values: export_data.flatten)

      Sidekiq::Testing.inline! do
        described_class.perform_async(facility_identifier.id, total_months)
      end
    end
  end

  describe "#format_gender_age_data" do
    subject { described_class.new.send(:format_gender_age_data, gender_age_data) }

    let(:gender_age_data) { {["female", 33] => 74, ["male", 96] => 72, ["female", 31] => 4, ["male", 8] => 6} }
    it "returns the data in gender and age range key" do
      output = subject
      expect(output.count).to eq 8
      expect(output["18_29_male"]).to eq 0
      expect(output["30_39_male"]).to eq 0
      expect(output["40_69_male"]).to eq 0
      expect(output["70_200_male"]).to eq 72
      expect(output["18_29_female"]).to eq 0
      expect(output["30_39_female"]).to eq 78
      expect(output["40_69_female"]).to eq 0
      expect(output["70_200_female"]).to eq 0
    end

    context "with empty gender age data" do
      let(:gender_age_data) { {} }

      it "returns zero for all the ranges" do
        output = subject
        expect(output.count).to eq 8
        expect(output.values.uniq).to eq [0]
      end
    end
  end

  describe "#format_treatment_data" do
    it "returns the data segregated with treatment type" do
      Timecop.freeze("April 25th 2024") do
        create_list(:patient, 3, :hypertension, :under_care)
        Reports::PatientState.refresh
      end
      patients = Reports::PatientState.all.to_a
      output = described_class.new.send(:format_treatment_data, patients)
      expect(output.count).to eq 2
      expect(output["lsm"]).to eq patients.count
      expect(output["pharma_mangement"]).to eq 0
    end

    it "returns 0 count with an empty data set" do
      output = described_class.new.send(:format_treatment_data, [])
      expect(output.count).to eq 2
      expect(output["lsm"]).to eq 0
      expect(output["pharma_mangement"]).to eq 0
    end
  end

  describe "#format_enrollment_data" do
    it "returns the data segregated by enrollment time" do
      Timecop.freeze("April 25th 2024") do
        create_list(:patient, 3, :hypertension, :under_care)
        Reports::PatientState.refresh
      end
      patients = Reports::PatientState.all.to_a
      output = described_class.new.send(:format_enrollment_data, patients)
      expect(output.count).to eq 2
      expect(output["newly_enrolled"]).to eq 3
      expect(output["previously_enrolled"]).to eq(patients.count - 3)
    end

    it "returns 0 count with an empty data set" do
      output = described_class.new.send(:format_enrollment_data, [])
      expect(output.count).to eq 2
      expect(output["newly_enrolled"]).to eq 0
      expect(output["previously_enrolled"]).to eq 0
    end
  end

  describe "#format_cohort_data" do
    it "returns the data segregated by enrollment time" do
      Timecop.freeze("April 25th 2024") do
        create(:patient, :hypertension, :controlled)
        create(:patient, :hypertension, :uncontrolled)
        create(:patient, :hypertension, :lost_to_follow_up)
        create(:patient, :hypertension, :dead)
        create(:patient, :hypertension, status: "migrated")
        refresh_views
      end
      patients = Reports::PatientState.all.to_a
      controlled_count = patients.count { |patient| patient.htn_care_state == "under_care" && patient.last_bp_state == "controlled" }
      uncontrolled_count = patients.count { |patient| patient.htn_care_state == "under_care" && patient.last_bp_state == "uncontrolled" }
      output = described_class.new.send(:format_cohort_data, patients)
      expect(output.count).to eq 5
      expect(output["controlled"]).to eq controlled_count
      expect(output["uncontrolled"]).to eq uncontrolled_count
    end
  end
end
