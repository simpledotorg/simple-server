# frozen_string_literal: true

require "rails_helper"

RSpec.describe PatientImport::SpreadsheetTransformer do
  let(:fixture_path) { File.join(Rails.root, "spec", "fixtures", "files", "patient_import_test.xlsx") }
  let(:data) { Roo::Spreadsheet.open(fixture_path).to_csv }
  let(:facility) { create(:facility) }

  it "parses patient data" do
    params = PatientImport::SpreadsheetTransformer.call(data, facility: facility)

    import_user = PatientImport::ImportUser.find_or_create
    patient = params.find { |p| p[:patient][:full_name] == "Basic Patient 1" }.deep_symbolize_keys
    patient_id = patient[:patient][:id]
    registration_time = Time.parse("2020-10-16").rfc3339
    last_visit_time = Time.parse("2021-02-24").rfc3339

    expect(patient[:patient]).to include(
      age: 45,
      age_updated_at: registration_time,
      full_name: "Basic Patient 1",
      gender: "male",
      recorded_at: registration_time,
      registration_facility_id: facility.id,
      assigned_facility_id: facility.id,
      status: "active"
    )

    expect(patient[:patient][:phone_numbers]).to contain_exactly(
      hash_including(
        number: "936528787",
        phone_type: "mobile",
        active: true,
        created_at: registration_time,
        updated_at: registration_time
      )
    )

    expect(patient[:patient][:address]).to include(
      country: "India",
      state: "Addis Ababa",
      street_address: "45 Main Street",
      village_or_colony: "Berrytown",
      zone: "Fruit County",
      district: "Vegetable District",
      created_at: registration_time,
      updated_at: registration_time
    )

    expect(patient[:patient][:business_identifiers]).to contain_exactly(
      hash_including(
        identifier: "0000001",
        identifier_type: "ethiopia_medical_record",
        metadata: {
          assigning_user_id: import_user.id,
          assigning_facility_id: facility.id
        }.to_json,
        metadata_version: "org.simple.ethiopia_medical_record.meta.v1",
        created_at: registration_time,
        updated_at: registration_time
      )
    )

    expect(patient[:medical_history]).to include(
      patient_id: patient_id,
      chronic_kidney_disease: "yes",
      diabetes: "no",
      hypertension: "yes",
      prior_heart_attack: "unknown",
      prior_stroke: "no"
    )

    expect(patient[:blood_pressures]).to contain_exactly(
      hash_including(
        patient_id: patient_id,
        systolic: 160,
        diastolic: 90,
        recorded_at: registration_time,
        created_at: registration_time,
        updated_at: registration_time
      ),
      hash_including(
        patient_id: patient_id,
        systolic: 145,
        diastolic: 89,
        recorded_at: last_visit_time,
        created_at: last_visit_time,
        updated_at: last_visit_time
      )
    )

    expect(patient[:prescription_drugs]).to contain_exactly(
      # first visit drugs deleted
      hash_including(
        name: "Amlodipine",
        dosage: "5 mg",
        rxnorm_code: "329528",
        is_deleted: true,
        is_protocol_drug: true,
        created_at: registration_time,
        updated_at: last_visit_time,
        deleted_at: last_visit_time
      ),
      hash_including(
        name: "Enalapril",
        dosage: "5 mg",
        rxnorm_code: "833236",
        is_deleted: true,
        is_protocol_drug: false,
        created_at: registration_time,
        updated_at: last_visit_time,
        deleted_at: last_visit_time
      ),
      hash_including(
        name: "Aspirin",
        dosage: "75 mg",
        rxnorm_code: "315429",
        is_deleted: true,
        is_protocol_drug: false,
        created_at: registration_time,
        updated_at: last_visit_time,
        deleted_at: last_visit_time
      ),
      hash_including(
        name: "Hydrochlorothiazide",
        dosage: "12.5 mg",
        rxnorm_code: "429503",
        is_deleted: true,
        is_protocol_drug: false,
        created_at: registration_time,
        updated_at: last_visit_time,
        deleted_at: last_visit_time
      ),
      hash_including(
        name: "Lisinopril",
        dosage: "5 mg",
        rxnorm_code: "316156",
        is_deleted: true,
        is_protocol_drug: false,
        created_at: registration_time,
        updated_at: last_visit_time,
        deleted_at: last_visit_time
      ),
      # second visit drugs not deleted
      hash_including(
        name: "Amlodipine",
        dosage: "10 mg",
        rxnorm_code: "329526",
        is_deleted: false,
        is_protocol_drug: false,
        created_at: last_visit_time,
        updated_at: last_visit_time
      )
    )
  end

  it "captures other patient attributes" do
    params = PatientImport::SpreadsheetTransformer.call(data, facility: facility)

    patient = params.find { |p| p[:patient][:full_name] == "Basic Patient 2" }

    expect(patient[:patient][:gender]).to eq("female")
    expect(patient[:patient][:status]).to eq("dead")
  end

  context "when last visit is absent" do
    it "retains BP from first visit" do
      params = PatientImport::SpreadsheetTransformer.call(data, facility: facility)
      patient = params.find { |p| p[:patient][:full_name] == "No Last Visit" }
      registration_time = Time.parse("2020-10-16").rfc3339

      expect(patient[:blood_pressures]).to contain_exactly(
        hash_including(systolic: 160, diastolic: 90, recorded_at: registration_time)
      )
    end

    it "does not delete prescription drugs from first visit" do
      params = PatientImport::SpreadsheetTransformer.call(data, facility: facility)
      patient = params.find { |p| p[:patient][:full_name] == "No Last Visit" }

      patient[:prescription_drugs].each do |drug|
        expect(drug[:is_deleted]).to be_falsey
        expect(drug[:deleted_at]).to be_nil
      end
    end
  end

  context "when address fields are missing" do
    let(:fixture_path) { File.join(Rails.root, "spec", "fixtures", "files", "patient_import_without_address_test.xlsx") }

    it "defaults to the facility's address" do
      params = PatientImport::SpreadsheetTransformer.call(data, facility: facility)

      patient = params.find { |p| p[:patient][:full_name] == "Basic Patient 1" }.deep_symbolize_keys
      registration_time = Time.parse("2020-10-16").rfc3339

      expect(patient[:patient][:address]).to include(
        country: "India",
        state: facility.state,
        street_address: "45 Main Street",
        village_or_colony: "Berrytown",
        zone: facility.zone,
        district: facility.district,
        created_at: registration_time,
        updated_at: registration_time
      )
    end
  end

  context "when rxnorm code is missing" do
    it "omits rxnorm code from the payload" do
      params = PatientImport::SpreadsheetTransformer.call(data, facility: facility)

      patient = params.find { |p| p[:patient][:full_name] == "No Rxnorm Code" }.deep_symbolize_keys

      expect(patient[:prescription_drugs].first).not_to have_key(:rxnorm_code)
    end
  end

  context "for abbreviated genders" do
    it "recognizes 'm'" do
      params = PatientImport::SpreadsheetTransformer.call(data, facility: facility)

      patient = params.find { |p| p[:patient][:full_name] == "Gender Abbrev M" }.deep_symbolize_keys

      expect(patient[:patient][:gender]).to eq("male")
    end

    it "recognizes 'f'" do
      params = PatientImport::SpreadsheetTransformer.call(data, facility: facility)

      patient = params.find { |p| p[:patient][:full_name] == "Gender Abbrev F" }.deep_symbolize_keys

      expect(patient[:patient][:gender]).to eq("female")
    end

    it "recognizes 't'" do
      params = PatientImport::SpreadsheetTransformer.call(data, facility: facility)

      patient = params.find { |p| p[:patient][:full_name] == "Gender Abbrev T" }.deep_symbolize_keys

      expect(patient[:patient][:gender]).to eq("transgender")
    end
  end

  context "for unrecognized genders" do
    let(:fixture_path) { File.join(Rails.root, "spec", "fixtures", "files", "patient_import_invalid_data_test.xlsx") }

    it "passes unrecognized values through untouched" do
      params = PatientImport::SpreadsheetTransformer.call(data, facility: facility)

      patient = params.find { |p| p[:patient][:full_name] == "Random Gender" }.deep_symbolize_keys

      expect(patient[:patient][:gender]).to eq("Potato")
    end
  end

  context "for abbreviated died? status" do
    it "recognizes 'Y'" do
      params = PatientImport::SpreadsheetTransformer.call(data, facility: facility)

      patient = params.find { |p| p[:patient][:full_name] == "Died Abbrev Y" }.deep_symbolize_keys

      expect(patient[:patient][:status]).to eq("dead")
    end

    it "recognizes 'N'" do
      params = PatientImport::SpreadsheetTransformer.call(data, facility: facility)

      patient = params.find { |p| p[:patient][:full_name] == "Died Abbrev N" }.deep_symbolize_keys

      expect(patient[:patient][:status]).to eq("active")
    end

    it "considers unrecognized values as 'no'" do
      params = PatientImport::SpreadsheetTransformer.call(data, facility: facility)

      patient = params.find { |p| p[:patient][:full_name] == "Died Abbrev Random" }.deep_symbolize_keys

      expect(patient[:patient][:status]).to eq("active")
    end
  end

  context "with no registration date" do
    it "ignores the row" do
      params = PatientImport::SpreadsheetTransformer.call(data, facility: facility)

      patient_names = params.map { |p| p[:patient][:full_name] }

      expect(patient_names).not_to include("No Registration Date")
    end
  end
end
