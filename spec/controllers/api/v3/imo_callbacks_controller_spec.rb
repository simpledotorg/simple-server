require "rails_helper"

RSpec.describe Api::V3::ImoCallbacksController, type: :controller do
  describe "#subscribe" do
    it "returns 401 when authentication fails" do
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

      it "raises error if patient is not found" do
        params = {patient_id: "does_not_exist", event: "accept_invite"}

        post :subscribe, params: params
        expect(response.status).to eq(404)
      end

      it "raises error if patient does not have an imo authorization record" do
        patient = create(:patient)
        params = {patient_id: patient.id, event: "accept_invite"}

        post :subscribe, params: params
        expect(response.status).to eq(400)
      end

      it "raises an error if when event is not 'accept_invite'" do
        patient = create(:patient)
        imo_auth = create(:imo_authorization, patient: patient)
        params = {patient_id: patient.id, event: "reject_invite"}

        expect {
          post :subscribe, params: params
        }.not_to change { imo_auth.reload.status }
        expect(response.status).to eq(400)
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
    end
  end

  describe "#read_receipt" do
    it "returns 401 when authentication fails" do
      post :read_receipt, params: {notification_id: "does_not_matter"}
      expect(response.status).to eq(401)
    end

    context "with valid authentication" do
      before :each do
        request.env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials(
          ENV["IMO_CALLBACK_USERNAME"],
          ENV["IMO_CALLBACK_PASSWORD"]
        )
      end

      it "raises an error when notification is not found" do
        params = {notification_id: "does_not_exist"}

        post :read_receipt, params: params
        expect(response.status).to eq(404)
      end

      it "raises an error when notification does not have an imo communication" do
        notification = create(:notification)
        params = {notification_id: notification.id}

        post :read_receipt, params: params

        expect(response.status).to eq(404)
      end

      it "raises an error when the notification does not have an imo delivery detail" do
        notification = create(:notification)
        communication = create(:communication, communication_type: "imo", notification: notification)
        params = {notification_id: notification.id}

        post :read_receipt, params: params

        expect(response.status).to eq(404)
      end

      it "updates the notification's imo delivery detail status to 'read'" do
        notification = create(:notification)
        detail = create(:imo_delivery_detail)
        communication = create(:communication, communication_type: "imo", notification: notification, detailable: detail)
        params = {notification_id: notification.id}

        expect {
          post :read_receipt, params: params
        }.to change{detail.reload.result}.from("sent").to("read")
        expect(response.status).to eq(200)
      end

      it "returns 400 if the result is changed to 'read' multiple times" do
        notification = create(:notification)
        detail = create(:imo_delivery_detail, result: "read", created_at: 10.minutes.ago)
        communication = create(:communication, communication_type: "imo", notification: notification, detailable: detail)
        params = {notification_id: notification.id}

        expect(Rails.logger).to receive(:error).with("detail #{detail.id} already marked read")
        expect {
          post :read_receipt, params: params
        }.not_to change{detail.reload}
        expect(response.status).to eq(200)
      end
    end
  end
end
