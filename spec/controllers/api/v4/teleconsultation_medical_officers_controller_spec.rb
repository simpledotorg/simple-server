require "rails_helper"

def set_authentication_headers
  request.env["HTTP_X_USER_ID"] = request_user.id
  request.env["HTTP_X_FACILITY_ID"] = request_facility.id
  request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
end

RSpec.describe Api::V4::TeleconsultationMedicalOfficersController, type: :controller do
  describe "#sync_to_user" do
    let(:facility_group) { create(:facility_group) }

    let!(:request_facility) { create(:facility, facility_group: facility_group) }
    let(:request_user) { create(:user, registration_facility: request_facility) }
    let!(:facility_2) { create(:facility, facility_group: facility_group) }
    let!(:facility_without_any_mos) { create(:facility, facility_group: facility_group) }

    let!(:request_facility_teleconsultation_mo) {
      create(:teleconsultation_medical_officer, teleconsultation_facilities: [request_facility])
    }
    let!(:facility_2_teleconsultation_mos) {
      create_list(:teleconsultation_medical_officer,
        2,
        teleconsultation_facilities: [facility_2])
    }

    before do
      set_authentication_headers
    end

    it "sends a list of medical officers for all facilities in the facility group" do
      get :sync_to_user

      response_body = JSON(response.body)
      medical_officers = response_body["teleconsultation_medical_officers"].map { |r|
        [r["facility_id"], r["medical_officers"]]
      }.to_h

      expect(medical_officers[request_facility.id].first["id"]).to eq request_facility_teleconsultation_mo.id
      expect(medical_officers[facility_2.id].map { |m| m["id"] }).to match_array facility_2_teleconsultation_mos.map(&:id)
      expect(medical_officers[facility_without_any_mos.id]).to be_empty
    end
  end
end
