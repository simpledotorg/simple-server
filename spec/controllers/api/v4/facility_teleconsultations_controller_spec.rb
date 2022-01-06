# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V4::FacilityTeleconsultationsController, type: :controller do
  describe "#phone_number" do
    let(:user) { create(:user) }
    let(:isd_code) { Faker::PhoneNumber.country_code }
    let(:phone_number) { Faker::PhoneNumber.phone_number }

    before do
      request.env["HTTP_X_USER_ID"] = user.id
      request.env["HTTP_X_FACILITY_ID"] = user.registration_facility.id
      request.env["HTTP_AUTHORIZATION"] = "Bearer #{user.access_token}"
    end

    context "Teleconsultation is enabled and phone number is set up" do
      context "Requested facility is user's registration facility" do
        it "returns the phone number" do
          medical_officer = create(:user, teleconsultation_phone_number: "11111111", teleconsultation_isd_code: "+91")
          facility = user.registration_facility

          facility.enable_teleconsultation = true
          facility.teleconsultation_medical_officers = [medical_officer]
          facility.save!

          get :show, params: {facility_id: user.registration_facility.id}
          expect(response).to have_http_status(200)
          expect(JSON.parse(response.body)["teleconsultation_phone_number"]).to eq(Phonelib.parse("+91" + "11111111").full_e164)
          expect(JSON.parse(response.body)["teleconsultation_phone_numbers"]).to eq([{"phone_number" => Phonelib.parse("+91" + "11111111").full_e164}])
        end
      end

      context "Requested facility is user's registration facility" do
        it "returns multiple phone numbers" do
          medical_officer_1 = create(:user, teleconsultation_phone_number: "11111111", teleconsultation_isd_code: "+91")
          medical_officer_2 = create(:user, teleconsultation_phone_number: "22222222", teleconsultation_isd_code: "+91")
          facility = user.registration_facility

          facility.enable_teleconsultation = true
          facility.teleconsultation_medical_officers = [medical_officer_1, medical_officer_2]
          facility.save!

          expected_phone_number_1 = Phonelib.parse("+91" + "11111111").full_e164
          expected_phone_number_2 = Phonelib.parse("+91" + "22222222").full_e164

          get :show, params: {facility_id: user.registration_facility.id}
          expect(response).to have_http_status(200)
          expect(JSON.parse(response.body)["teleconsultation_phone_number"]).to be_in([expected_phone_number_1, expected_phone_number_2])
          expect(JSON.parse(response.body)["teleconsultation_phone_numbers"]).to match_array([
            {"phone_number" => expected_phone_number_1},
            {"phone_number" => expected_phone_number_2}
          ])
        end
      end

      context "Requested facility is in the user's Facility Group" do
        it "returns the phone number" do
          facility = create(:facility, facility_group: user.registration_facility.facility_group)
          medical_officer = create(:user, teleconsultation_phone_number: phone_number, teleconsultation_isd_code: isd_code)

          facility.enable_teleconsultation = true
          facility.teleconsultation_medical_officers = [medical_officer]
          facility.save!

          get :show, params: {facility_id: facility.id}
          expect(response).to have_http_status(200)
          expect(JSON.parse(response.body)["teleconsultation_phone_number"]).to eq(Phonelib.parse(isd_code + phone_number).full_e164)
        end
      end

      context "Requested facility is not in the user's Facility Group" do
        it "fails authorization" do
          medical_officer = create(:user, teleconsultation_phone_number: phone_number, teleconsultation_isd_code: isd_code)
          facility = create(:facility)

          facility.enable_teleconsultation = false
          facility.teleconsultation_medical_officers = [medical_officer]
          facility.save!

          get :show, params: {facility_id: facility.id}
          expect(response).to have_http_status(401)
        end
      end
    end

    context "Teleconsultation is disabled or phone number is not set up" do
      context "teleconsultation is disabled" do
        it "returns the phone number" do
          medical_officer = create(:user, teleconsultation_phone_number: phone_number, teleconsultation_isd_code: isd_code)
          facility = user.registration_facility

          facility.enable_teleconsultation = false
          facility.teleconsultation_medical_officers = [medical_officer]
          facility.save!

          get :show, params: {facility_id: user.registration_facility.id}
          expect(response).to have_http_status(200)
          expect(JSON.parse(response.body)["teleconsultation_phone_number"]).to eq(Phonelib.parse(isd_code + phone_number).full_e164)
        end
      end
    end
  end
end
