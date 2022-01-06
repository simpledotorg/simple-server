# frozen_string_literal: true

require "rails_helper"

def set_authentication_headers
  request.env["HTTP_X_USER_ID"] = request_user.id
  request.env["HTTP_X_FACILITY_ID"] = request_facility.id
  request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
end

RSpec.describe Api::V4::FacilityMedicalOfficersController, type: :controller do
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
      medical_officers = response_body["facility_medical_officers"].map { |facility|
        [facility["facility_id"], facility["medical_officers"]]
      }.to_h

      expect(medical_officers[request_facility.id].first["id"]).to eq request_facility_teleconsultation_mo.id
      expect(medical_officers[facility_2.id].map { |m| m["id"] }).to match_array facility_2_teleconsultation_mos.map(&:id)
      expect(medical_officers[facility_without_any_mos.id]).to be_empty
    end

    it "sets the appropriate timestamp fields" do
      Timecop.freeze do
        get :sync_to_user

        response_body = JSON(response.body)
        medical_officers = response_body["facility_medical_officers"]

        expect(medical_officers.map { |medical_officer| Time.parse(medical_officer["created_at"]).to_i }).to all eq Time.current.to_i
        expect(medical_officers.map { |medical_officer| Time.parse(medical_officer["updated_at"]).to_i }).to all eq Time.current.to_i
        expect(medical_officers.map { |medical_officer| medical_officer["deleted_at"] }).to all be nil
      end
    end
  end
end
