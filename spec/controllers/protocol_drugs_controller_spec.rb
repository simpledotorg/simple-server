require 'rails_helper'

RSpec.describe ProtocolDrugsController, type: :controller do

  let(:valid_attributes) {
    protocol = FactoryBot.create(:protocol)
    FactoryBot.attributes_for(:protocol_drug, protocol_id: protocol.id)
  }

  let(:invalid_attributes) {
    protocol = FactoryBot.create(:protocol)
    FactoryBot.attributes_for(:protocol_drug, name: nil, protocol_id: protocol.id)
  }

  describe "GET #index" do
    it "returns a success response" do
      protocol_drug = ProtocolDrug.create! valid_attributes
      get :index, params: {}
      expect(response).to be_success
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      protocol_drug = ProtocolDrug.create! valid_attributes
      get :show, params: {id: protocol_drug.to_param}
      expect(response).to be_success
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {}
      expect(response).to be_success
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      protocol_drug = ProtocolDrug.create! valid_attributes
      get :edit, params: {id: protocol_drug.to_param}
      expect(response).to be_success
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new ProtocolDrug" do
        expect {
          post :create, params: {protocol_drug: valid_attributes}
        }.to change(ProtocolDrug, :count).by(1)
      end

      it "redirects to the list of protocols" do
        post :create, params: {protocol_drug: valid_attributes}
        expect(response).to redirect_to(:protocols)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: {protocol_drug: invalid_attributes}
        expect(response).to be_success
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        protocol = FactoryBot.create(:protocol)
        FactoryBot.attributes_for(:protocol_drug, protocol_id: protocol.id).except(:id)
      }

      it "updates the requested protocol_drug" do
        protocol_drug = ProtocolDrug.create! valid_attributes
        put :update, params: {id: protocol_drug.to_param, protocol_drug: new_attributes}
        protocol_drug.reload
        expect(protocol_drug.attributes.except('id', 'created_at', 'updated_at'))
          .to eq new_attributes.with_indifferent_access
      end

      it "redirects to the list of protocols" do
        protocol_drug = ProtocolDrug.create! valid_attributes
        put :update, params: {id: protocol_drug.to_param, protocol_drug: valid_attributes}
        expect(response).to redirect_to(:protocols)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        protocol_drug = ProtocolDrug.create! valid_attributes
        put :update, params: {id: protocol_drug.to_param, protocol_drug: invalid_attributes}
        expect(response).to be_success
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested protocol_drug" do
      protocol_drug = ProtocolDrug.create! valid_attributes
      expect {
        delete :destroy, params: {id: protocol_drug.to_param}
      }.to change(ProtocolDrug, :count).by(-1)
    end

    it "redirects to the protocol_drugs list" do
      protocol_drug = ProtocolDrug.create! valid_attributes
      delete :destroy, params: {id: protocol_drug.to_param}
      expect(response).to redirect_to(protocol_drugs_url)
    end
  end

end
