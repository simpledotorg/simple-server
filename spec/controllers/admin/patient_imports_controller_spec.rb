require "rails_helper"

RSpec.describe Admin::PatientImportsController, type: :controller do
  include ActiveJob::TestHelper

  describe "GET #new" do
    it "returns a success response for power users" do
      admin = create(:admin, :power_user)
      sign_in(admin.email_authentication)

      get :new
      expect(response).to be_successful
    end

    it "denies access to other users" do
      admin = create(:admin, :manager)
      sign_in(admin.email_authentication)

      get :new
      expect(response).to be_redirect
    end
  end

  describe "POST #create" do
    context "with valid data in file" do
      it "imports the patients" do
        admin = create(:admin, :power_user)
        sign_in(admin.email_authentication)

        timezone = CountryConfig.current[:time_zone]
        facility = create(:facility)
        patient_import_file = fixture_file_upload("files/patient_import_test.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        params = {patient_import_file: patient_import_file, facility_id: facility.id}

        perform_enqueued_jobs do
          post :create, params: params
        end

        basic_patient_1 = Patient.find_by(full_name: "Basic Patient 1")
        basic_patient_2 = Patient.find_by(full_name: "Basic Patient 2")
        no_last_visit_patient = Patient.find_by(full_name: "No Last Visit")
        no_meds_in_last_visit_patient = Patient.find_by(full_name: "No Meds In Last Visit")

        # Ensure all patients are imported
        expect(basic_patient_1).to be_present
        expect(basic_patient_2).to be_present
        expect(no_last_visit_patient).to be_present
        expect(no_meds_in_last_visit_patient).to be_present

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
        }.join(", ")

        expect(basic_patient_1_bps).to eq("160/90, 145/89")

        # Patient 1 prescription drugs
        basic_patient_1_prescription_drugs = basic_patient_1.prescription_drugs.map { |pd|
          "#{pd.name} #{pd.dosage}"
        }.join(", ")

        expect(basic_patient_1_prescription_drugs).to eq("Amlodipine 10 mg")
      end

      it "displays a success message" do
        admin = create(:admin, :power_user)
        sign_in(admin.email_authentication)

        facility = create(:facility)
        patient_import_file = fixture_file_upload("files/patient_import_test.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        params = {patient_import_file: patient_import_file, facility_id: facility.id}

        post :create, params: params
        expect(flash[:notice]).to match(/imported 4 patients.*#{facility.name}/)
      end
    end

    context "with invalid file" do
      it "raises validation errors" do
        admin = create(:admin, :power_user)
        sign_in(admin.email_authentication)

        facility = create(:facility)
        patient_import_file = fixture_file_upload("files/patient_import_invalid_data_test.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        params = {patient_import_file: patient_import_file, facility_id: facility.id}

        expect { post :create, params: params }.not_to change { Patient.count }
        expect(assigns(:errors)[3]).to include(/full_name/)
      end
    end

    context "for non-power users" do
      it "denies access to import patients" do
        admin = create(:admin, :manager)
        sign_in(admin.email_authentication)

        facility = create(:facility)
        patient_import_file = fixture_file_upload("files/patient_import_test.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        params = {patient_import_file: patient_import_file, facility_id: facility.id}

        expect { post :create, params: params }.not_to change { Patient.count }
      end
    end
  end
end
