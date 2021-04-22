require "rails_helper"

RSpec.describe PatientImport::SpreadsheetTransformer do
  let(:fixture_path) { File.join(Rails.root, "spec", "fixtures", "files", "patient_import_test.xlsx") }
  let(:data) { Roo::Spreadsheet.open(fixture_path).to_csv }
  let(:facility) { create(:facility) }

  it "works" do
    params = PatientImport::SpreadsheetTransformer.transform(data, facility: facility)

    patient = params.find {|p| p[:patient][:full_name] == "Example Patient" }

    expect(patient[:patient]).to eq(
      age: "45",
      full_name: "Example Patient",
      gender: "Male",
      recorded_at: "2020-10-16",
      registration_facility_id: nil,
      status: :active
    )

    expect(patient[:phone_number]).to eq(
      number: "936528787",
      phone_type: :mobile,
      active: true
    )

    expect(patient[:address]).to eq(
      country: "India",
      state: "Addis Ababa",
      street_address: "45 Main Street",
      village_or_colony: "Berrytown",
      zone: "Fruit County"
    )

    expect(patient[:business_identifier]).to eq(
      identifier: "0000001",
      identifier_type: "ethiopia_medical_record"
    )

    expect(patient[:medical_history]).to eq(
      chronic_kidney_disease: "yes",
      diabetes: "no",
      hypertension: "yes",
      prior_heart_attack: "unknown",
      prior_stroke: "no"
    )

    expect(patient[:blood_pressures]).to contain_exactly(
      {:systolic=>"160", :diastolic=>"90", :recorded_at=>"2020-01-29"},
      {:systolic=>"145", :diastolic=>"89", :recorded_at=>"2021-02-24"}
    )

    expect(patient[:prescription_drugs]).to contain_exactly(
      # first visit drugs deleted
      {
        :created_at=>"2020-01-29",
        :deleted_at=>"2021-02-24",
        :dosage=>"5 mg",
        :is_deleted=>true,
        :is_protocol_drug=>true,
        :name=>"Amlodipine",
        :rxnorm_code=>"329528"
      },
      # second visit drugs not deleted
      {
        :created_at=>"2021-02-24",
        :dosage=>"10 mg",
        :is_protocol_drug=>false,
        :name=>"Amlodipine",
        :rxnorm_code=>"329526"
      }
    )
  end
end
