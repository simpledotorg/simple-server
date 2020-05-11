require 'rails_helper'

RSpec.describe Admin::FacilitiesController, type: :controller do
  let(:facility_group) { create(:facility_group) }
  let(:valid_attributes) do
    attributes_for(
      :facility,
      facility_group_id: facility_group.id
    )
  end

  let(:invalid_attributes) do
    attributes_for(
      :facility,
      name: nil
    )
  end

  before do
    admin = create(:admin, :supervisor, facility_group: facility_group)
    sign_in(admin.email_authentication)
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index, params: { facility_group_id: facility_group.id }
      expect(response).to be_success
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      facility = Facility.create! valid_attributes
      get :show, params: { id: facility.to_param, facility_group_id: facility_group.id }
      expect(response).to be_success
    end
  end

  describe 'GET #new' do
    it 'returns a success response' do
      get :new, params: { facility_group_id: facility_group.id }
      expect(response).to be_success
    end
  end

  describe 'GET #edit' do
    it 'returns a success response' do
      facility = Facility.create! valid_attributes
      get :edit, params: { id: facility.to_param, facility_group_id: facility_group.id }
      expect(response).to be_success
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Facility' do
        expect do
          post :create, params: { facility: valid_attributes, facility_group_id: facility_group.id }
        end.to change(Facility, :count).by(1)
      end

      it 'redirects to the facilities' do
        post :create, params: { facility: valid_attributes, facility_group_id: facility_group.id }
        expect(response).to redirect_to [:admin, facility_group, assigns(:facility)]
      end
    end

    context 'with invalid params' do
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: { facility: invalid_attributes, facility_group_id: facility_group.id }
        expect(response).to be_success
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        attributes_for(
          :facility,
          facility_group_id: facility_group.id,
          pin: '999999',
          monthly_estimated_opd_load: 500
        ).except(:id, :slug)
      end

      it 'updates the requested facility' do
        facility = Facility.create! valid_attributes
        put :update, params: { id: facility.to_param, facility: new_attributes, facility_group_id: facility_group.id }
        facility.reload
        expect(facility.attributes.except('id', 'created_at', 'updated_at', 'deleted_at', 'slug',
                                          'facility_group_name', 'import', 'latitude', 'longitude',
                                          'organization_name'))
          .to eq new_attributes.with_indifferent_access
      end

      it 'redirects to the facility' do
        facility = Facility.create! valid_attributes
        put :update, params: { id: facility.to_param, facility: valid_attributes, facility_group_id: facility_group.id }
        expect(response).to redirect_to [:admin, facility_group, facility]
      end
    end

    context 'with invalid params' do
      it "returns a success response (i.e. to display the 'edit' template)" do
        facility = Facility.create! valid_attributes
        put :update, params: { id: facility.to_param, facility: invalid_attributes, facility_group_id: facility_group.id }
        expect(response).to be_success
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested facility' do
      facility = Facility.create! valid_attributes
      expect do
        delete :destroy, params: { id: facility.to_param, facility_group_id: facility_group.id }
      end.to change(Facility, :count).by(-1)
    end

    it 'redirects to the facilities list' do
      facility = Facility.create! valid_attributes
      delete :destroy, params: { id: facility.to_param, facility_group_id: facility_group.id }
      expect(response).to redirect_to(admin_facilities_url)
    end
  end

  describe 'GET #upload' do
    it 'returns a successful response' do
      get :upload
      expect(response).to be_success
    end
  end

  describe 'POST #upload' do
    context 'with valid organization and facility group' do
      let(:organization) { FactoryBot.create(:organization, name: 'OrgOne') }
      let!(:facility_group_2) do
        FactoryBot.create(:facility_group, name: 'FGTwo',
                                           organization_id: organization.id)
      end
      let(:upload_file) { fixture_file_upload('files/upload_facilities_test.csv', 'text/csv') }
      it 'uploads facilities file and passes validations' do
        post :upload, params: { upload_facilities_file: upload_file }
        expect(flash[:notice]).to match(/File upload successful, your facilities will be created shortly./)
      end
    end

    context 'with duplicate rows' do
      let(:organization) { FactoryBot.create(:organization, name: 'OrgOne') }
      let!(:facility_group_2) do
        FactoryBot.create(:facility_group, name: 'FGTwo',
                                           organization_id: organization.id)
      end
      let(:upload_file) { fixture_file_upload('files/upload_facilities_test_2.csv', 'text/csv') }
      it 'uploads facilities file and fails validations' do
        post :upload, params: { upload_facilities_file: upload_file }
        expect(assigns(:errors)).to eq(['Uploaded file has duplicate facilities',
                                        "Row(s) 2, 4: Facility group doesn't exist for the organization",
                                        "Row(s) 3: Organization doesn't exist",
                                        "Row(s) 5: Facility group doesn't exist for the organization and District can't be blank"])
      end
    end
    context 'with invalid organization and facility group' do
      let(:organization) { FactoryBot.create(:organization, name: 'OrgOne') }
      let!(:facility_group_2) do
        FactoryBot.create(:facility_group, name: 'FGTwo',
                                           organization_id: organization.id)
      end
      let(:upload_file) { fixture_file_upload('files/upload_facilities_test_3.csv', 'text/csv') }
      it 'uploads facilities file and fails validations' do
        post :upload, params: { upload_facilities_file: upload_file }
        expect(assigns(:errors)).to eq(["Row(s) 2: Facility group doesn't exist for the organization",
                                        "Row(s) 3: Organization doesn't exist",
                                        "Row(s) 4: Facility group doesn't exist for the organization and District can't be blank",
                                        "Row(s) 5: Organization name can't be blank"])
      end
    end
    context 'with unsupported file type' do
      let(:upload_file) do
        fixture_file_upload('files/upload_facilities.docx',
                            'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
      end
      it 'uploads facilities file and fails validations' do
        post :upload, params: { upload_facilities_file: upload_file }
        expect(assigns(:errors)).to eq(['File type not supported, please upload a csv or xlsx file instead'])
      end
    end
  end
end
