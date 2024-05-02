require "rails_helper"

describe PatientStates::Hypertension::RegistrationsUnderCareQuery do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  let(:regions) { setup_district_with_facilities }
  let(:period) { Period.current }

  context 'hyperstension under care patients' do
    it 'returns patients under care and with hypertension' do
      hypertension_under_care_patients = create_list(:patient, 2, :hypertension, :under_care, registration_facility: regions[:facility_1])
      refresh_views
      expect(PatientStates::Hypertension::RegistrationsUnderCareQuery.new(regions[:facility_1].region, period).call.count).to eq(2)
      expect(PatientStates::Hypertension::RegistrationsUnderCareQuery.new(regions[:facility_1].region, period).call
        .map{|x| x.patient_id}).to eq(hypertension_under_care_patients.map{|x| x.id})
    end

    it 'does not return patient in another facility' do
      facility_1_patients = create_list(:patient, 2, :hypertension, :under_care, registration_facility: regions[:facility_1])
      facility_2_patients = create_list(:patient, 2, :hypertension, :under_care, registration_facility: regions[:facility_2])
      refresh_views
      expect(PatientStates::Hypertension::RegistrationsUnderCareQuery.new(regions[:facility_1].region, period).call.count).to eq(2)
      expect(PatientStates::Hypertension::RegistrationsUnderCareQuery.new(regions[:facility_1].region, period).call
        .map{|x| x.patient_id}).not_to include(facility_2_patients.map{|x| x.id})
    end

    it 'only includes hyperternsion patients' do
      hypertension_under_care_patients = create_list(:patient, 2, :hypertension, :under_care, registration_facility: regions[:facility_1])
      diabetes_under_care_patients = create_list(:patient, 2, :diabetes, :under_care, registration_facility: regions[:facility_1])
      refresh_views
      expect(PatientStates::Hypertension::RegistrationsUnderCareQuery.new(regions[:facility_1].region, period).call.count).to eq(2)
      expect(PatientStates::Hypertension::RegistrationsUnderCareQuery.new(regions[:facility_1].region, period).call
        .map{|x| x.patient_id}).not_to include(diabetes_under_care_patients.map{|x| x.id})
    end
  end
end
