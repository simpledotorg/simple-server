require "rails_helper"

describe PatientStates::Hypertension::RegistrationsUnderCareGenderAgeAggregatedQuery do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  let(:regions) { setup_district_with_facilities }
  let(:period) { Period.current }

  context "hyperstension under care patients" do
    it "returns data aggreagated by gender and age" do
      create(:patient, :hypertension, :under_care, registration_facility: regions[:facility_1], gender: "male", age: 19)
      create(:patient, :hypertension, :under_care, registration_facility: regions[:facility_1], gender: "male", age: 75)
      create(:patient, :hypertension, :under_care, registration_facility: regions[:facility_1], gender: "male", age: 75)
      create(:patient, :hypertension, :under_care, registration_facility: regions[:facility_1], gender: "female", age: 20)
      create(:patient, :hypertension, :under_care, registration_facility: regions[:facility_1], gender: "female", age: 40)

      refresh_views
      expect(PatientStates::Hypertension::RegistrationsUnderCareGenderAgeAggregatedQuery.new(regions[:facility_1].region, period).call.count).to eq(4)
      expect(PatientStates::Hypertension::RegistrationsUnderCareGenderAgeAggregatedQuery.new(regions[:facility_1].region, period).call)
        .to eq({["female", 20] => 1, ["female", 40] => 1, ["male", 19] => 1, ["male", 75] => 2})
    end

    it "does not return patient in another facility" do
      create(:patient, :hypertension, :under_care, registration_facility: regions[:facility_1], gender: "male", age: 19)
      create(:patient, :hypertension, :under_care, registration_facility: regions[:facility_2], gender: "male", age: 19)
      refresh_views
      expect(PatientStates::Hypertension::RegistrationsUnderCareGenderAgeAggregatedQuery.new(regions[:facility_1].region, period).call.count).to eq(1)
      expect(PatientStates::Hypertension::RegistrationsUnderCareGenderAgeAggregatedQuery.new(regions[:facility_1].region, period).call)
        .to eq({["male", 19] => 1})
    end

    it "only includes hyperternsion patients" do
      create(:patient, :hypertension, :under_care, registration_facility: regions[:facility_1], gender: "male", age: 19)
      create(:patient, :diabetes, :under_care, registration_facility: regions[:facility_1], gender: "male", age: 19)
      refresh_views
      expect(PatientStates::Hypertension::RegistrationsUnderCareGenderAgeAggregatedQuery.new(regions[:facility_1].region, period).call.count).to eq(1)
      expect(PatientStates::Hypertension::RegistrationsUnderCareGenderAgeAggregatedQuery.new(regions[:facility_1].region, period).call)
        .to eq({["male", 19] => 1})
    end
  end
end
