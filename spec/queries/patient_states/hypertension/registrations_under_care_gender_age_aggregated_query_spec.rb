require "rails_helper"

describe PatientStates::Hypertension::RegistrationsUnderCareGenderAgeAggregatedQuery do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  let(:regions) { setup_district_with_facilities }
  let(:period) { Period.current }

  context 'hyperstension under care patients' do
    it 'returns data aggreagated by gender and age' do
      male_19_patient = create(:patient, :hypertension, :under_care, registration_facility: regions[:facility_1], gender: "male", age: 19)
      male_75_patient = create(:patient, :hypertension, :under_care, registration_facility: regions[:facility_1], gender: "male", age: 75)
      male_75_patient_2 = create(:patient, :hypertension, :under_care, registration_facility: regions[:facility_1], gender: "male", age: 75)
      female_20_patient = create(:patient, :hypertension, :under_care, registration_facility: regions[:facility_1], gender: "female", age: 20)
      female_40_patient = create(:patient, :hypertension, :under_care, registration_facility: regions[:facility_1], gender: "female", age: 40)
      
      refresh_views
      expect(PatientStates::Hypertension::RegistrationsUnderCareGenderAgeAggregatedQuery.new(regions[:facility_1].region, period).call.count).to eq(4)
      expect(PatientStates::Hypertension::RegistrationsUnderCareGenderAgeAggregatedQuery.new(regions[:facility_1].region, period).call)
        .to eq({["female", 20]=>1, ["female", 40]=>1, ["male", 19]=>1, ["male", 75]=>2})
    end

    it 'does not return patient in another facility' do
      facility_1_patient = create(:patient, :hypertension, :under_care, registration_facility: regions[:facility_1], gender: "male", age: 19)
      facility_2_patient = create(:patient, :hypertension, :under_care, registration_facility: regions[:facility_2], gender: "male", age: 19)
      refresh_views
      expect(PatientStates::Hypertension::RegistrationsUnderCareGenderAgeAggregatedQuery.new(regions[:facility_1].region, period).call.count).to eq(1)
      expect(PatientStates::Hypertension::RegistrationsUnderCareGenderAgeAggregatedQuery.new(regions[:facility_1].region, period).call)
        .to eq({["male", 19]=>1})
    end

    it 'only includes hyperternsion patients' do
      hypertension_under_care_patient = create(:patient, :hypertension, :under_care, registration_facility: regions[:facility_1], gender: "male", age: 19)
      diabetes_under_care_patients = create(:patient, :diabetes, :under_care, registration_facility: regions[:facility_1], gender: "male", age: 19)
      refresh_views
      expect(PatientStates::Hypertension::RegistrationsUnderCareGenderAgeAggregatedQuery.new(regions[:facility_1].region, period).call.count).to eq(1)
      expect(PatientStates::Hypertension::RegistrationsUnderCareGenderAgeAggregatedQuery.new(regions[:facility_1].region, period).call)
        .to eq({["male", 19]=>1})
    end
  end
end
