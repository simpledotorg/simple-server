# frozen_string_literal: true

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
      end

      it "displays a success message" do
        admin = create(:admin, :power_user)
        sign_in(admin.email_authentication)

        facility = create(:facility)
        patient_import_file = fixture_file_upload("files/patient_import_test.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        params = {patient_import_file: patient_import_file, facility_id: facility.id}

        post :create, params: params
        expect(flash[:notice]).to match(/imported 11 patients.*#{facility.name}/)
      end
    end

    context "with invalid data" do
      it "raises validation errors for the bad rows" do
        admin = create(:admin, :power_user)
        sign_in(admin.email_authentication)

        facility = create(:facility)
        patient_import_file = fixture_file_upload("files/patient_import_invalid_data_test.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        params = {patient_import_file: patient_import_file, facility_id: facility.id}

        expect { post :create, params: params }.not_to change { Patient.count }
        expect(assigns(:errors)[3]).to include(/full_name/)
      end
    end

    context "with invalid file format" do
      it "raises validation errors for the missing headers" do
        admin = create(:admin, :power_user)
        sign_in(admin.email_authentication)

        facility = create(:facility)
        patient_import_file = fixture_file_upload("files/patient_import_missing_headers_test.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        params = {patient_import_file: patient_import_file, facility_id: facility.id}

        expect { post :create, params: params }.not_to change { Patient.count }
        expect(assigns(:errors)["Headers"]).to include(/age/)
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
