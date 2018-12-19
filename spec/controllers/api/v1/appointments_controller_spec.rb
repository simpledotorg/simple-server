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

  def create_record(options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    FactoryBot.create(:appointment, options.merge(facility: facility))
  end

  def create_record_list(n, options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    FactoryBot.create_list(:appointment, n, options.merge(facility: facility))
  end

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

  describe 'syncing within a facility group' do
    let(:facility_in_same_group) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
    let(:facility_in_another_group) { FactoryBot.create(:facility) }

    before :each do
      set_authentication_headers
      FactoryBot.create_list(:appointment, 5, facility: facility_in_another_group, updated_at: 3.minutes.ago)
      FactoryBot.create_list(:appointment, 5, facility: facility_in_same_group, updated_at: 5.minutes.ago)
    end

    it "only sends data for facilities belonging in the sync group of user's registration facility" do
      get :sync_to_user, params: { limit: 15 }

      response_appointments = JSON(response.body)['appointments']
      response_facilities = response_appointments.map { |appointment| appointment['facility_id']}.to_set

      expect(response_appointments.count).to eq 5
      expect(response_facilities).not_to include(facility_in_another_group.id)

    end
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

    it 'does not coerce old reasons' do
      set_authentication_headers
      v1_cancel_reasons = Appointment.cancel_reasons.keys.map(&:to_sym) - [:invalid_phone_number, :public_hospital_transfer, :moved_to_private]
      appointments = 10.times.map {|_| FactoryBot.create(:appointment, cancel_reason: v1_cancel_reasons.sample) }

      get :sync_to_user
      response_body = JSON(response.body)
      expect(response_body['appointments'].count).to eq 10
      expect(response_body['appointments'].map{|a|a['cancel_reason']}).to eq(appointments.map(&:cancel_reason))
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
