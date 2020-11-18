require "rails_helper"

RSpec.describe Admin::FacilityGroupsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:protocol) { create(:protocol) }
  let(:valid_attributes) do
    attributes_for(
      :facility_group,
      organization_id: organization.id,
      state: "An State",
      protocol_id: protocol.id
    )
  end

  let(:invalid_attributes) do
    attributes_for(
      :facility_group,
      name: nil,
      organization_id: organization.id
    )
  end

  before do
    admin = create(:admin, :manager, :with_access, resource: organization, organization: organization)
    sign_in(admin.email_authentication)
  end

  describe "GET #show" do
    it "returns a success response" do
      facility_group = create(:facility_group, valid_attributes)
      get :show, params: {id: facility_group.to_param, organization_id: organization.id}

      expect(response).to be_successful
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {organization_id: organization.id}

      expect(response).to be_successful
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      facility_group = create(:facility_group, valid_attributes)
      get :edit, params: {id: facility_group.to_param, organization_id: organization.id}

      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new FacilityGroup" do
        expect {
          post :create, params: {facility_group: valid_attributes, organization_id: organization.id}
        }.to change(FacilityGroup, :count).by(1)
      end

      it "redirects to the facilities" do
        post :create, params: {facility_group: valid_attributes, organization_id: organization.id}
        expect(response).to redirect_to(admin_facilities_url)
      end

      it "creates state if supplied" do
        enable_flag(:regions_prep)

        organization = create(:organization)
        admin = create(:admin, :manager, :with_access, resource: organization, organization: organization)
        sign_in(admin.email_authentication)
        protocol = create(:protocol)
        valid_attributes =
          attributes_for(
            :facility_group,
            organization_id: organization.id,
            state: "An State",
            protocol_id: protocol.id
          )

        expect {
          post :create, params: {facility_group: valid_attributes, organization_id: organization.id}
        }.to change(Region.state_regions, :count).by(1)
      end

      it "creates the children blocks" do
        enable_flag(:regions_prep)

        organization = create(:organization)
        admin = create(:admin, :manager, :with_access, resource: organization, organization: organization)
        sign_in(admin.email_authentication)
        protocol = create(:protocol)
        valid_attributes =
          attributes_for(
            :facility_group,
            organization_id: organization.id,
            state: "An State",
            protocol_id: protocol.id
          )
        attrs_with_blocks = valid_attributes.merge(new_blocks: ["Block A", "Block B"])

        expect {
          post :create, params: {facility_group: attrs_with_blocks, organization_id: organization.id}
        }.to change(Region.block_regions, :count).by(2)
      end
    end

    context "with invalid params" do
      it "returns a 400 response" do
        post :create, params: {facility_group: invalid_attributes, organization_id: organization.id}
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) do
        FactoryBot.attributes_for(
          :facility_group,
          organization_id: organization.id,
          protocol_id: protocol.id
        ).except(:id, :slug)
      end

      it "updates the requested facility_group" do
        facility_group = create(:facility_group, valid_attributes)
        put :update, params: {id: facility_group.to_param, facility_group: new_attributes, organization_id: organization.id}
        facility_group.reload

        expect(facility_group.attributes.except("id", "created_at", "updated_at", "deleted_at", "slug", "enable_diabetes_management"))
          .to eq new_attributes.except(:state).with_indifferent_access
      end

      it "redirects to the facilities" do
        facility_group = create(:facility_group, valid_attributes)
        put :update, params: {id: facility_group.to_param, facility_group: valid_attributes, organization_id: organization.id}

        expect(response).to redirect_to(admin_facilities_url)
      end

      it "updates the block regions" do
        enable_flag(:regions_prep)

        organization = create(:organization)
        admin = create(:admin, :manager, :with_access, resource: organization, organization: organization)
        sign_in(admin.email_authentication)
        protocol = create(:protocol)
        valid_attributes =
          attributes_for(
            :facility_group,
            organization_id: organization.id,
            state: "An State",
            protocol_id: protocol.id
          )
        facility_group = create(:facility_group, valid_attributes)
        attr_with_blocks = valid_attributes.merge(new_blocks: ["Block A", "Block B"])

        expect {
          put :update, params: {id: facility_group.to_param, facility_group: attr_with_blocks, organization_id: organization.id}
        }.to change(Region.block_regions, :count).by(2)

        attrs_with_block_removed = valid_attributes.merge(remove_blocks: [Region.block_regions.last.id])
        expect {
          put :update, params: {id: facility_group.to_param, facility_group: attrs_with_block_removed, organization_id: organization.id}
        }.to change(Region.block_regions, :count).by(-1)
      end
    end

    context "with invalid params" do
      it "returns a 400 response (i.e. against the 'edit' template)" do
        facility_group = create(:facility_group, valid_attributes)
        put :update, params: {id: facility_group.to_param, facility_group: invalid_attributes, organization_id: organization.id}

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested facility_group" do
      facility_group = create(:facility_group, valid_attributes)
      expect {
        delete :destroy, params: {id: facility_group.to_param, organization_id: organization.id}
      }.to change(FacilityGroup, :count).by(-1)
    end

    it "redirects to the facilities list" do
      facility_group = create(:facility_group, valid_attributes)
      delete :destroy, params: {id: facility_group.to_param, organization_id: organization.id}

      expect(response).to redirect_to(admin_facilities_url)
    end
  end
end
