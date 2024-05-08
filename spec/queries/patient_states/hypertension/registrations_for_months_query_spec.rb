require "rails_helper"

describe PatientStates::Hypertension::RegistrationsForMonthsQuery do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  let(:regions) { setup_district_with_facilities }
  let(:period) { Period.current }

  context "hyperstension under care patients" do
    it "returns patients registered for provided month" do
      Timecop.freeze("April 25th 2024") do
        seven_months_ago = Time.parse("April 25th 2024") - 7.months
        six_months_ago = Time.parse("April 25th 2024") - 6.months
        five_months_ago = Time.parse("April 25th 2024") - 5.months
        create(:patient, :hypertension, registration_facility: regions[:facility_1], recorded_at: seven_months_ago)
        create(:patient, :hypertension, registration_facility: regions[:facility_1], recorded_at: five_months_ago)
        patient_six_months = create(:patient, :hypertension, registration_facility: regions[:facility_1], recorded_at: six_months_ago)
        refresh_views

        expect(PatientStates::Hypertension::RegistrationsForMonthsQuery.new(regions[:facility_1].region, period, 6).call.count).to eq(1)
        expect(PatientStates::Hypertension::RegistrationsForMonthsQuery.new(regions[:facility_1].region, period, 6).call
          .map { |x| x.patient_id }).to eq([patient_six_months.id])
      end
    end

    it "does not return patient in another facility" do
      Timecop.freeze("April 25th 2024") do
        six_months_ago = Time.parse("April 25th 2024") - 6.months
        create(:patient, :hypertension, registration_facility: regions[:facility_1], recorded_at: six_months_ago)
        patient_six_months_facility_2 = create(:patient, :hypertension, registration_facility: regions[:facility_2], recorded_at: six_months_ago)
        refresh_views

        expect(PatientStates::Hypertension::RegistrationsForMonthsQuery.new(regions[:facility_1].region, period, 6).call.count).to eq(1)
        expect(PatientStates::Hypertension::RegistrationsForMonthsQuery.new(regions[:facility_1].region, period, 6).call
          .map { |x| x.patient_id }).not_to include(patient_six_months_facility_2.id)
      end
    end

    it "only includes hyperternsion patients" do
      Timecop.freeze("April 25th 2024") do
        six_months_ago = Time.parse("April 25th 2024") - 6.months
        patient_six_months_diabetes = create(:patient, :diabetes, registration_facility: regions[:facility_1], recorded_at: six_months_ago)
        create(:patient, :hypertension, registration_facility: regions[:facility_1], recorded_at: six_months_ago)
        refresh_views

        expect(PatientStates::Hypertension::RegistrationsForMonthsQuery.new(regions[:facility_1].region, period, 6).call.count).to eq(1)
        expect(PatientStates::Hypertension::RegistrationsForMonthsQuery.new(regions[:facility_1].region, period, 6).call
          .map { |x| x.patient_id }).not_to eq(patient_six_months_diabetes.id)
      end
    end
  end
end
