require 'rails_helper'

RSpec.describe Api::V4::FacilityTeleconsultationsController, type: :controller do
  describe '#phone_number' do
    let(:user) { FactoryBot.create(:user) }
    let(:isd_code) { Faker::PhoneNumber.country_code }
    let(:phone_number) { Faker::PhoneNumber.phone_number }

    before do
      request.env['HTTP_X_USER_ID'] = user.id
      request.env['HTTP_X_FACILITY_ID'] = user.registration_facility.id
      request.env['HTTP_AUTHORIZATION'] = "Bearer #{user.access_token}"
    end

    context 'Teleconsultation is enabled and phone number is set up' do
      context "Requested facility is user's registration facility" do
        it 'returns the phone number' do
          user.registration_facility.update!(enable_teleconsultation: true,
                                             teleconsultation_isd_code: isd_code,
                                             teleconsultation_phone_number: phone_number)

          get :show, params: { facility_id: user.registration_facility.id }
          expect(response).to have_http_status(200)
          expect(JSON.parse(response.body)['teleconsultation_phone_number']).to eq(isd_code + phone_number)
        end
      end

      context "Requested facility is in the user's Facility Group" do
        it 'returns the phone number' do
          facility = create(:facility, facility_group: user.registration_facility.facility_group)
          facility.update!(enable_teleconsultation: true,
                           teleconsultation_isd_code: isd_code,
                           teleconsultation_phone_number: phone_number)

          get :show, params: { facility_id: facility.id }
          expect(response).to have_http_status(200)
          expect(JSON.parse(response.body)['teleconsultation_phone_number']).to eq(isd_code + phone_number)
        end
      end

      context "Requested facility is not in the user's Facility Group" do
        it 'fails authorization' do
          facility = create(:facility)
          facility.update!(enable_teleconsultation: true,
                           teleconsultation_isd_code: isd_code,
                           teleconsultation_phone_number: phone_number)

          get :show, params: { facility_id: facility.id }
          expect(response).to have_http_status(401)
        end
      end
    end

    context 'Teleconsultation is disabled or phone number is not set up' do
      context 'teleconsultation is disabled' do
        it 'returns the phone number' do
          user.registration_facility.update!(enable_teleconsultation: false,
                                             teleconsultation_isd_code: isd_code,
                                             teleconsultation_phone_number: phone_number)

          get :show, params: { facility_id: user.registration_facility.id }
          expect(response).to have_http_status(200)
          expect(JSON.parse(response.body)['teleconsultation_phone_number']).to eq(isd_code + phone_number)
        end
      end

      context 'ISD code is nil' do
        it 'returns a null phone number' do
          user.registration_facility.update_columns(enable_teleconsultation: true,
                                                    teleconsultation_isd_code: nil,
                                                    teleconsultation_phone_number: phone_number)

          get :show, params: { facility_id: user.registration_facility.id }
          expect(response).to have_http_status(200)
          expect(JSON.parse(response.body)['teleconsultation_phone_number']).to be_nil
        end
      end

      context 'phone number is nil' do
        it 'returns a null phone number' do
          user.registration_facility.update_columns(enable_teleconsultation: true,
                                                    teleconsultation_isd_code: isd_code,
                                                    teleconsultation_phone_number: nil)

          get :show, params: { facility_id: user.registration_facility.id }
          expect(response).to have_http_status(200)
          expect(JSON.parse(response.body)['teleconsultation_phone_number']).to be_nil
        end
      end
    end
  end
end
