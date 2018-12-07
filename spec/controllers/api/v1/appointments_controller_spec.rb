require 'rails_helper'

RSpec.describe Api::V1::AppointmentsController, type: :controller do
  let(:request_user) { FactoryBot.create(:user) }
  before :each do
    request.env['X_USER_ID'] = request_user.id
    request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
  end

  let(:model) { Appointment }

  let(:build_payload) { lambda { build_appointment_payload } }
  let(:build_invalid_payload) { lambda { build_invalid_appointment_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { lambda { |appointment| updated_appointment_payload appointment } }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }

  it_behaves_like 'a sync controller that authenticates user requests'
  it_behaves_like 'a sync controller that audits the data access'
  it_behaves_like 'a working sync controller that short circuits disabled apis'

  describe 'POST sync: send data from device to server;' do
    it_behaves_like 'a working sync controller creating records'
    it_behaves_like 'a working sync controller updating records'
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'a working V1 sync controller sending records'
  end

  describe 'New cancel_reasons are compatible with v1' do
    it 'coerces new reasons into other' do
      set_authentication_headers

      FactoryBot.create_list(:appointment, 10, cancel_reason: [:invalid_phone_number, :public_hospital_transfer, :moved_to_private].sample)

      get :sync_to_user
      response_body = JSON(response.body)
      expect(response_body['appointments'].count).to eq 10
      expect(response_body['appointments'].map{|a|a['cancel_reason']}.to_set).to eq(Set['other'])
    end

    it 'does not allow cancelled appointments to be updated' do
      set_authentication_headers
      cancelled_appointment = FactoryBot.create(:appointment, status: :cancelled, cancel_reason: [:invalid_phone_number, :public_hospital_transfer, :moved_to_private].sample)
      post(:sync_from_user, params: {appointments: [build_appointment_payload(cancelled_appointment).merge(updated_at: Time.now)]}, as: :json)

      response_body = JSON(response.body).with_indifferent_access
      expect(response.status).to eq(200)
      expect(response_body['errors'].first['updated_at']).to eq('Cancelled appointment cannot be updated')
    end
  end
end
