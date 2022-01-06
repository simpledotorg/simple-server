# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V3::ImoCallbacksController, type: :controller do
  describe "#subscribe" do
    # Skipping this since Imo callbacks aren't authenticated for now
    xit "returns 401 when authentication fails" do
      post :subscribe, params: {patient_id: "does_not_matter", event: "accept_invite"}
      expect(response.status).to eq(401)
    end

    context "with valid authentication" do
      before :each do
        request.env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials(
          ENV["IMO_CALLBACK_USERNAME"],
          ENV["IMO_CALLBACK_PASSWORD"]
        )
      end

      it "returns 200 and updates the patient's imo auth" do
        patient = create(:patient)
        imo_auth = create(:imo_authorization, patient: patient)
        params = {patient_id: patient.id, event: "accept_invite"}

        expect {
          post :subscribe, params: params
        }.to change { imo_auth.reload.status }.from("invited").to("subscribed")
        expect(response.status).to eq(200)
      end

      it "returns 404 if patient is not found" do
        params = {patient_id: "does_not_exist", event: "accept_invite"}

        post :subscribe, params: params
        expect(response.status).to eq(404)
      end

      it "returns 400 if patient does not have an imo authorization record" do
        patient = create(:patient)
        params = {patient_id: patient.id, event: "accept_invite"}

        post :subscribe, params: params
        expect(response.status).to eq(400)
      end

      it "returns 400 when event is not 'accept_invite'" do
        patient = create(:patient)
        imo_auth = create(:imo_authorization, patient: patient)
        params = {patient_id: patient.id, event: "reject_invite"}

        expect {
          post :subscribe, params: params
        }.not_to change { imo_auth.reload.status }
        expect(response.status).to eq(400)
      end
    end
  end

  describe "#read_receipt" do
    # Skipping this since Imo callbacks aren't authenticated for now
    xit "returns 401 when authentication fails" do
      post :read_receipt
      expect(response.status).to eq(401)
    end

    context "with valid authentication" do
      before :each do
        request.env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials(
          ENV["IMO_CALLBACK_USERNAME"],
          ENV["IMO_CALLBACK_PASSWORD"]
        )
      end

      it "updates the imo_delivery_detail status to 'read' and returns 200" do
        detail = create(:imo_delivery_detail, post_id: "find_me")
        params = {post_id: "find_me", event: "read_receipt"}

        expect {
          post :read_receipt, params: params
        }.to change { detail.reload.result }.from("sent").to("read")
          .and change { detail.read_at }.from(nil)
        expect(response.status).to eq(200)
      end

      it "returns 404 when imo_delivery_detail is not found" do
        params = {post_id: "does_not_exist", event: "read_receipt"}

        post :read_receipt, params: params
        expect(response.status).to eq(404)
      end

      it "returns 400 when event is not 'read_receipt'" do
        params = {post_id: "does_not_exist", event: "rejected"}

        post :read_receipt, params: params
        expect(response.status).to eq(400)
      end

      it "returns 200 if the result is changed to 'read' multiple times" do
        detail = create(:imo_delivery_detail, result: "read", post_id: "find_me", created_at: 10.minutes.ago)
        params = {post_id: "find_me", event: "read_receipt"}

        expect(Rails.logger).to receive(:error).with(
          class: "Api::V3::ImoCallbacksController", msg: "detail #{detail.id} already marked read"
        )
        expect {
          post :read_receipt, params: params
        }.not_to change { detail.reload }
        expect(response.status).to eq(200)
      end
    end
  end
end
