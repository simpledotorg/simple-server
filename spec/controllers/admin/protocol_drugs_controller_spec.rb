# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ProtocolDrugsController, type: :controller do
  let(:protocol) { FactoryBot.create(:protocol) }
  let(:valid_attributes) do
    FactoryBot.attributes_for(:protocol_drug, protocol_id: protocol.id)
  end

  let(:invalid_attributes) do
    FactoryBot.attributes_for(:protocol_drug, name: nil, protocol_id: protocol.id)
  end

  before do
    admin = create(:admin, :power_user)
    sign_in(admin.email_authentication)
  end

  describe "GET #index" do
    it "returns a success response" do
      ProtocolDrug.create! valid_attributes
      get :index, params: {protocol_id: protocol.id}
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      protocol_drug = ProtocolDrug.create! valid_attributes
      get :show, params: {id: protocol_drug.to_param, protocol_id: protocol.id}
      expect(response).to be_successful
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {protocol_id: protocol.id}
      expect(response).to be_successful
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      protocol_drug = ProtocolDrug.create! valid_attributes
      get :edit, params: {id: protocol_drug.to_param, protocol_id: protocol.id}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new ProtocolDrug" do
        expect {
          post :create, params: {protocol_drug: valid_attributes, protocol_id: protocol.id}
        }.to change(ProtocolDrug, :count).by(1)
      end

      it "redirects to the list of protocols" do
        post :create, params: {protocol_drug: valid_attributes, protocol_id: protocol.id}
        expect(response).to redirect_to([:admin, protocol])
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: {protocol_drug: invalid_attributes, protocol_id: protocol.id}
        expect(response).to be_successful
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) do
        FactoryBot.attributes_for(:protocol_drug, protocol_id: protocol.id).except(:id)
      end

      it "updates the requested protocol_drug" do
        protocol_drug = ProtocolDrug.create! valid_attributes
        put :update, params: {id: protocol_drug.to_param, protocol_drug: new_attributes, protocol_id: protocol.id}
        protocol_drug.reload
        expect(protocol_drug.attributes.except("id", "created_at", "updated_at", "deleted_at"))
          .to eq new_attributes.with_indifferent_access
      end

      it "redirects to the list of protocols" do
        protocol_drug = ProtocolDrug.create! valid_attributes
        put :update, params: {id: protocol_drug.to_param, protocol_drug: valid_attributes, protocol_id: protocol.id}
        expect(response).to redirect_to([:admin, protocol])
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        protocol_drug = ProtocolDrug.create! valid_attributes
        put :update, params: {id: protocol_drug.to_param, protocol_drug: invalid_attributes, protocol_id: protocol.id}
        expect(response).to be_successful
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested protocol_drug" do
      protocol_drug = ProtocolDrug.create! valid_attributes
      expect {
        delete :destroy, params: {id: protocol_drug.to_param, protocol_id: protocol.id}
      }.to change(ProtocolDrug, :count).by(-1)
    end

    it "redirects to the protocol_drugs list" do
      protocol_drug = ProtocolDrug.create! valid_attributes
      delete :destroy, params: {id: protocol_drug.to_param, protocol_id: protocol.id}
      expect(response).to redirect_to([:admin, protocol])
    end
  end
end
