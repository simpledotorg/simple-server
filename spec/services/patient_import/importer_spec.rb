require "rails_helper"

RSpec.describe PatientImport::Importer do
  describe "#import" do
    it "imports valid patient information" do
      facility = create(:facility)
      admin = create(:admin)
      timezone = CountryConfig.current[:time_zone]
      data = file_fixture("patient_import_test.csv").read

      params = PatientImport::SpreadsheetTransformer.call(data, facility: facility)
      params.each do |patient_params|
        PatientImport::Importer.new(params: patient_params, facility: facility, admin: admin).import
      end

      basic_patient_1 = Patient.find_by(full_name: "Basic Patient 1")
      basic_patient_2 = Patient.find_by(full_name: "Basic Patient 2")

      expect(basic_patient_1).to be_present
      expect(basic_patient_2).to be_present

      # Dig into patient 1's details extensively
      # Patient 1 attributes
      expect(basic_patient_1.attributes).to include(
        "age" => 45,
        "gender" => "male",
        "status" => "active"
      )
      expect(basic_patient_1.recorded_at.in_time_zone(timezone).to_date).to eq(Date.parse("2020-10-16"))

      # Patient 1 address
      expect(basic_patient_1.address.attributes).to include(
        "street_address" => "45 Main Street",
        "village_or_colony" => "Berrytown",
        "zone" => "Fruit County",
        "state" => "Addis Ababa",
        "country" => CountryConfig.current[:name]
      )

      # Patient 1 phone number
      expect(basic_patient_1.latest_phone_number).to eq("936528787")

      # Patient 1 business identifier
      expect(basic_patient_1.business_identifiers.last.attributes).to include(
        "identifier" => "0000001",
        "identifier_type" => "ethiopia_medical_record"
      )

      # Patient 1 BPs
      basic_patient_1_bps = basic_patient_1.blood_pressures.map { |bp|
        "#{bp.systolic}/#{bp.diastolic}"
      }

      expect(basic_patient_1_bps).to contain_exactly("160/90", "145/89")

      # Patient 1 prescription drugs
      basic_patient_1_prescription_drugs = basic_patient_1.prescription_drugs.map { |pd|
        "#{pd.name} #{pd.dosage}"
      }.join(", ")

      expect(basic_patient_1_prescription_drugs).to eq("Amlodipine 10 mg")
    end
  end
end
