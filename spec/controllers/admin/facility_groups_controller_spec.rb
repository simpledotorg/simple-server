require "rails_helper"

RSpec.describe Admin::FacilityGroupsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:protocol) { create(:protocol) }
  let(:valid_attributes) do
    attributes_for(
      :facility_group,
      organization_id: organization.id,
      state: "New York",
      protocol_id: protocol.id
    )
  end

  let(:invalid_attributes) do
    attributes_for(
      :facility_group,
      name: nil,
      state: "An State",
      organization_id: organization.id,
      estimated_population: 0
    )
  end

  describe "GET requests" do
    before do
      admin = create(:admin, :manager, :with_access, resource: organization, organization: organization)
      sign_in(admin.email_authentication)
    end

    it "show returns a success response" do
      facility_group = create(:facility_group, valid_attributes)
      get :show, params: {id: facility_group.to_param, organization_id: organization.id}

      expect(response).to be_successful
    end

    it "new returns a success response" do
      get :new, params: {organization_id: organization.id}
      expect(response).to be_successful
    end

    it "edit returns a success response" do
      facility_group = create(:facility_group, valid_attributes)
      get :edit, params: {id: facility_group.to_param, organization_id: organization.id}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    render_views

    before do
      admin = create(:admin, :manager, :with_access, resource: organization, organization: organization)
      sign_in(admin.email_authentication)
    end

    it "creates a new FacilityGroup" do
      expect {
        post :create, params: {facility_group: valid_attributes, organization_id: organization.id}
      }.to change(FacilityGroup, :count).by(1)
    end

    it "creates a new FacilityGroup with estimated population set on district Region" do
      valid_attributes[:district_estimated_population] = 2500
      expect {
        post :create, params: {facility_group: valid_attributes, organization_id: organization.id}
      }.to change(FacilityGroup, :count).by(1)
        .and change(Region, :count).by(2) # creates district region and state region
        .and change(EstimatedPopulation, :count).by(2) # population for district and state
      fg = assigns(:facility_group)
      expect(fg.region.estimated_population.population).to eq 2500
      expect(fg.region.state_region.estimated_population.population).to eq 2500
    end

    it "does not create population for blank values" do
      valid_attributes[:district_estimated_population] = ""
      expect {
        post :create, params: {facility_group: valid_attributes, organization_id: organization.id}
      }.to change(FacilityGroup, :count).by(1)
        .and change(EstimatedPopulation, :count).by(0) # population for district and state
      fg = assigns(:facility_group)
      expect(fg.region.estimated_population).to be_nil
    end

    it "redirects to the facilities" do
      post :create, params: {facility_group: valid_attributes, organization_id: organization.id}
      expect(response).to redirect_to(admin_facilities_url)
    end

    it "creates state if supplied" do
      valid_attributes[:state] = "California"

      expect {
        post :create, params: {facility_group: valid_attributes, organization_id: organization.id}
      }.to change(Region.state_regions, :count).by(1)

      facility_group = assigns[:facility_group]
      expect(facility_group.region.state_region.name).to eq("California")
    end

    it "returns a 422 response for invalid attributes" do
      post :create, params: {facility_group: invalid_attributes, organization_id: organization.id}
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns a 422 response for record invalid" do
      attributes = valid_attributes.except(:protocol_id)
      post :create, params: {facility_group: attributes, organization_id: organization.id}
      expect(assigns(:facility_group).errors[:protocol]).to eq(["must exist"])
      expect(response.body).to match(/fix the following errors: protocol must exist/)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "creates the children blocks" do
      valid_attributes[:new_block_names] = ["Block A", "Block B"]

      expect {
        post :create, params: {facility_group: valid_attributes, organization_id: organization.id}
      }.to change(Region.block_regions, :count).by(2)
      facility_group = assigns[:facility_group]
      expect(facility_group.region.block_regions.map(&:name)).to contain_exactly("Block A", "Block B")
    end
  end

  describe "PUT #update" do
    render_views

    before do
      admin = create(:admin, :manager, :with_access, resource: organization, organization: organization)
      sign_in(admin.email_authentication)
    end

    it "updates the requested facility_group" do
      facility_group = create(:facility_group, valid_attributes)
      new_attributes = {
        name: "New Name",
        description: "New Description",
        state: "New York"
      }
      put :update, params: {id: facility_group.to_param, facility_group: new_attributes, organization_id: organization.id}
      expect(response).to be_redirect
      expect(flash.notice).to eq("Facility group was successfully updated.")
      facility_group.reload

      expect(facility_group.name).to eq("New Name")
      expect(facility_group.description).to eq("New Description")
      expect(facility_group.state).to eq("New York")
    end

    fit "updates when population is blank and no population exists" do
      facility_group = create(:facility_group, valid_attributes)
      new_attributes = {
        name: "New Name",
        district_estimated_population: "",
        description: "New Description",
        state: "New York"

      }
      put :update, params: {id: facility_group.to_param, facility_group: new_attributes, organization_id: organization.id}
    end

    it "can turn on diabetes management for all facilities inside a facility group" do
      facility_group = create(:facility_group, valid_attributes)
      facilities = create_list(:facility, 2, facility_group: facility_group, enable_diabetes_management: false)
      facilities.each { |facility| expect(facility.enable_diabetes_management).to be_falsey }
      new_attributes = {
        name: "New Name",
        description: "New Description",
        state: "New York",
        enable_diabetes_management: true
      }
      put :update, params: {id: facility_group.to_param, facility_group: new_attributes, organization_id: organization.id}
      facility_group.reload
      facilities.each { |facility| expect(facility.reload.enable_diabetes_management).to be_truthy }
      expect(facility_group.name).to eq("New Name")
      expect(facility_group.description).to eq("New Description")
      expect(facility_group.state).to eq("New York")
    end

    it "can create new estimated population" do
      valid_attributes[:district_estimated_population] = 2500
      facility_group = create(:facility_group, valid_attributes)
      expect(facility_group.district_estimated_population).to eq(2500)
      new_attributes = {
        district_estimated_population: 1500
      }
      put :update, params: {id: facility_group.to_param, facility_group: new_attributes, organization_id: organization.id}
      expect(response).to be_redirect
      expect(flash.notice).to eq("Facility group was successfully updated.")
      facility_group.reload
      expect(facility_group.region.reload_estimated_population.population).to eq(1500)
    end

    it "can update estimated population" do
      facility_group = create(:facility_group, valid_attributes)
      expect(facility_group.district_estimated_population).to be_nil
      new_attributes = {
        district_estimated_population: 1500
      }
      put :update, params: {id: facility_group.to_param, facility_group: new_attributes, organization_id: organization.id}
      expect(response).to be_redirect
      expect(flash.notice).to eq("Facility group was successfully updated.")
      expect(facility_group.estimated_population.population).to eq(1500)
    end

    it "destroys the estimated population if its blank" do
      valid_attributes[:district_estimated_population] = 100
      facility_group = create(:facility_group, valid_attributes)
      expect(facility_group.district_estimated_population).to eq(100)
      new_attributes = {
        district_estimated_population: ""
      }
      expect {
        put :update, params: {id: facility_group.to_param, facility_group: new_attributes, organization_id: organization.id}
      }.to change { EstimatedPopulation.count }.by(-1)
      expect(response).to be_redirect
      expect(flash.notice).to eq("Facility group was successfully updated.")
      expect(facility_group.estimated_population).to be_nil
    end

    it "redirects to the facilities" do
      facility_group = create(:facility_group, valid_attributes)
      put :update, params: {id: facility_group.to_param, facility_group: valid_attributes, organization_id: organization.id}

      expect(response).to redirect_to(admin_facilities_url)
    end

    it "returns a 422 response with invalid attributes (i.e. against the 'edit' template)" do
      facility_group = create(:facility_group, valid_attributes)
      put :update, params: {id: facility_group.to_param, facility_group: invalid_attributes, organization_id: organization.id}

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "disallows updating state" do
      facility_group = create(:facility_group, name: "Original Name", state: "New York")
      state_region = facility_group.region.state_region
      new_attributes = {
        name: "New Name",
        description: "New Description",
        state: "California"
      }
      expect {
        put :update, params: {id: facility_group.to_param, facility_group: new_attributes, organization_id: organization.id}
      }.to_not change(state_region, :name)

      expect(facility_group.reload.name).to eq("Original Name")
      expect(facility_group.state).to eq("New York")
    end

    it "updates the block regions" do
      facility_group = create(:facility_group, valid_attributes)
      region = facility_group.region

      expect {
        put :update, params: {id: facility_group.to_param, facility_group: {new_block_names: ["Block A", "Block B"]}, organization_id: organization.id}
      }.to change(region.block_regions, :count).by(2)
      expect(region.block_regions.map(&:name)).to contain_exactly("Block A", "Block B")

      block_a = region.block_regions.find_by!(name: "Block A")
      expect {
        put :update, params: {id: facility_group.to_param, facility_group: {remove_block_ids: [block_a.id]}, organization_id: organization.id}
      }.to change(region.block_regions, :count).by(-1)
      expect(region.block_regions.map(&:name)).to contain_exactly("Block B")
    end
  end

  describe "DELETE #destroy" do
    before do
      admin = create(:admin, :manager, :with_access, resource: organization, organization: organization)
      sign_in(admin.email_authentication)
    end

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
