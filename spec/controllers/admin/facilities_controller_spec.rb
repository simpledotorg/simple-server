# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::FacilitiesController, type: :controller do
  let(:facility_group) { create(:facility_group) }
  let(:block) { create(:region, :block, name: "Block A", reparent_to: facility_group.region) }
  let(:valid_attributes) do
    attributes_for(:facility,
      facility_group_id: facility_group.id,
      zone: block.name,
      enable_teleconsultation: false)
  end

  let(:invalid_attributes) do
    attributes_for(
      :facility,
      zone: "Invalid Block",
      name: nil
    )
  end

  before do
    admin = create(:admin, :manager, :with_access, resource: facility_group)
    sign_in(admin.email_authentication)
  end

  describe "GET #index" do
    it "returns a success response" do
      get :index, params: {facility_group_id: facility_group.id}
      expect(response).to be_successful
    end

    it "returns a subset of filtered facilities by search term" do
      _f = create(:facility, name: "HWC Dewa", facility_group: facility_group)
      f1 = create(:facility, name: "CH Jahangir", facility_group: facility_group)

      get :index, params: {facility_group_id: facility_group.id, search_query: "Jahangir"}
      expect(assigns(:facilities)).to eq({facility_group => [f1]})
      expect(response).to be_successful
    end

    it "fetches no facilities for search term with no matches" do
      create(:facility, name: "HWC Dewa", facility_group: facility_group)
      create(:facility, name: "CH Jahangir", facility_group: facility_group)

      get :index, params: {facility_group_id: facility_group.id, search_query: "CWC"}
      expect(assigns(:facilities)).to eq({})
      expect(response).to be_successful
    end
  end

  describe "GET #index.csv" do
    it "renders CSV of all accessible facility" do
      create_list(:facility, 3)
      power_user = create(:admin, :power_user)
      sign_in(power_user.email_authentication)
      get :index, format: :csv
      expect(response).to be_successful
      expect(response.body.lines.count).to eq(4)
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      facility = create(:facility, valid_attributes)
      get :show, params: {id: facility.to_param, facility_group_id: facility_group.id}
      expect(response).to be_successful
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {facility_group_id: facility_group.id}
      expect(response).to be_successful
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      facility = create(:facility, valid_attributes)
      get :edit, params: {id: facility.to_param, facility_group_id: facility_group.id}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Facility" do
        expect {
          post :create, params: {facility: valid_attributes, facility_group_id: facility_group.id}
        }.to change(Facility, :count).by(1)
      end

      it "redirects to the facilities" do
        post :create, params: {facility: valid_attributes, facility_group_id: facility_group.id}
        expect(response).to redirect_to [:admin, facility_group, assigns(:facility)]
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: {facility: invalid_attributes, facility_group_id: facility_group.id}
        expect(response).to be_successful
      end
    end

    context "with unauthorized teleconsult medical officers" do
      let(:valid_facility) { create(:facility, facility_group_id: facility_group.id) }
      let(:invalid_facility) { create(:facility) }
      let(:valid_medical_officer) { create(:user, registration_facility: valid_facility) }
      let(:another_valid_medical_officer) { create(:user, registration_facility: valid_facility) }
      let(:invalid_medical_officer) { create(:user, registration_facility: invalid_facility) }

      it "rejects unauthorized medical officers" do
        post :create, params: {
          facility: valid_attributes.merge(
            teleconsultation_medical_officer_ids: [valid_medical_officer.id, invalid_medical_officer.id]
          ),
          facility_group_id: facility_group.id
        }

        expect(assigns(:facility).teleconsultation_medical_officers).to contain_exactly(valid_medical_officer)
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) do
        attributes_for(:facility,
          facility_group_id: facility_group.id,
          pin: "999999",
          zone: block.name,
          monthly_estimated_opd_load: 500).except(:id, :slug)
      end

      it "updates the requested facility" do
        facility = create(:facility, valid_attributes)
        update_attributes = new_attributes

        put :update, params: {id: facility.to_param, facility: update_attributes, facility_group_id: facility_group.id}

        facility.reload

        expect(facility.attributes.except("id", "created_at", "updated_at", "deleted_at", "slug",
          "facility_group_name", "latitude", "longitude", "organization_name", "district", "state"))
          .to eq new_attributes.with_indifferent_access
      end

      it "redirects to the facility" do
        facility = create(:facility, valid_attributes)
        put :update, params: {id: facility.to_param, facility: valid_attributes, facility_group_id: facility_group.id}
        expect(response).to redirect_to [:admin, facility_group, facility]
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        facility = create(:facility, valid_attributes)
        put :update, params: {id: facility.to_param, facility: invalid_attributes, facility_group_id: facility_group.id}
        expect(response).to be_successful
      end
    end

    context "with unauthorized teleconsult medical officers" do
      let(:valid_facility) { create(:facility, facility_group_id: facility_group.id) }
      let(:invalid_facility) { create(:facility) }
      let(:valid_medical_officer) { create(:user, registration_facility: valid_facility) }
      let(:another_valid_medical_officer) { create(:user, registration_facility: valid_facility) }
      let(:invalid_medical_officer) { create(:user, registration_facility: invalid_facility) }

      it "rejects unauthorized medical officers" do
        post :create, params: {
          facility: valid_attributes.merge(
            teleconsultation_medical_officer_ids: [valid_medical_officer.id, invalid_medical_officer.id]
          ),
          facility_group_id: facility_group.id
        }

        expect(assigns(:facility).teleconsultation_medical_officers).to contain_exactly(valid_medical_officer)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested facility" do
      facility = create(:facility, valid_attributes)
      expect {
        delete :destroy, params: {id: facility.to_param, facility_group_id: facility_group.id}
      }.to change(Facility, :count).by(-1)
    end

    it "redirects to the facilities list" do
      facility = create(:facility, valid_attributes)
      delete :destroy, params: {id: facility.to_param, facility_group_id: facility_group.id}
      expect(response).to redirect_to(admin_facilities_url)
    end
  end

  describe "GET #upload" do
    it "returns a successful response" do
      get :upload
      expect(response).to be_successful
    end
  end

  describe "POST #upload" do
    let!(:organization) { create(:organization, name: "OrgOne") }
    let!(:facility_group) { create(:facility_group, name: "FGTwo", organization_id: organization.id) }

    context "with valid data in file" do
      let(:upload_file) { fixture_file_upload("files/upload_facilities_test.csv", "text/csv") }

      before do
        create(:region, :block, name: "Zone 1", reparent_to: facility_group.region)
        create(:region, :block, name: "Zone 2", reparent_to: facility_group.region)
      end

      it "uploads facilities file and passes validations" do
        post :upload, params: {upload_facilities_file: upload_file}
        expect(flash[:notice]).to match(/File upload successful, your facilities will be created shortly./)
      end
    end

    context "with invalid data in file" do
      let(:upload_file) { fixture_file_upload("files/upload_facilities_invalid_test.csv", "text/csv") }

      before do
        create(:region, :block, name: "Zone 1", reparent_to: facility_group.region)
        create(:region, :block, name: "Zone 2", reparent_to: facility_group.region)
      end

      it "fails validations and returns a 400" do
        post :upload, params: {upload_facilities_file: upload_file}
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with unsupported file type" do
      let(:upload_file) do
        fixture_file_upload("files/upload_facilities_test.docx",
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
      end

      before do
        create(:region, :block, name: "Zone 1", reparent_to: facility_group.region)
        create(:region, :block, name: "Zone 2", reparent_to: facility_group.region)
      end

      it "uploads facilities file and fails validations" do
        post :upload, params: {upload_facilities_file: upload_file}
        expect(assigns(:errors)).to eq(["File type not supported, please upload a csv or xlsx file instead"])
      end
    end
  end
end
