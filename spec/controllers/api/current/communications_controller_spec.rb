require 'rails_helper'

RSpec.describe Api::Current::CommunicationsController, type: :controller do
  let(:request_user) { FactoryBot.create(:user) }
  let(:request_facility) { FactoryBot.create(:facility) }
  before :each do
    request.env['X_USER_ID'] = request_user.id
    request.env['X_FACILITY_ID'] = request_facility.id
    request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
  end

  let(:model) { Communication }

  def create_record(options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    appointment = FactoryBot.create(:appointment, facility: facility)
    FactoryBot.create(:communication, options.merge(appointment: appointment))
  end

  def create_record_list(n, options = {})
    facility = FactoryBot.create(:facility, facility_group: request_user.facility.facility_group)
    appointment = FactoryBot.create(:appointment, facility: facility)
    FactoryBot.create_list(:communication, n, options.merge(appointment: appointment))
  end

  let(:build_payload) { lambda { build_communication_payload } }
  let(:build_invalid_payload) { lambda { build_invalid_communication_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { lambda { |communication| updated_communication_payload communication } }
  let(:number_of_schema_errors_in_invalid_payload) { 3 }

  it_behaves_like 'a sync controller that authenticates user requests'
  it_behaves_like 'a sync controller that audits the data access'
  it_behaves_like 'a working sync controller that short circuits disabled apis'

  describe 'POST sync: send data from device to server;' do
    it_behaves_like 'a working sync controller creating records'
    it_behaves_like 'a working sync controller updating records'
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'a working Current sync controller sending records'
  end

  describe 'syncing within a sync group' do
    let(:facility_in_same_group) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
    let(:facility_in_another_group) { FactoryBot.create(:facility) }
    let(:appointment_in_request_facility) { FactoryBot.create(:appointment, facility: request_facility) }
    let(:appointment_in_same_group) { FactoryBot.create(:appointment, facility: facility_in_same_group) }
    let(:appointment_in_another_group) { FactoryBot.create(:appointment, facility: facility_in_another_group) }

    before :each do
      set_authentication_headers

      FactoryBot.create_list(:communication, 5, appointment: appointment_in_request_facility, updated_at: 7.minutes.ago)
      FactoryBot.create_list(:communication, 5, appointment: appointment_in_same_group, updated_at: 5.minutes.ago)
      FactoryBot.create_list(:communication, 5, appointment: appointment_in_another_group, updated_at: 3.minutes.ago)
    end

    it "only sends data for facilities belonging in the sync group of user's registration facility" do
      get :sync_to_user, params: { limit: 15 }

      response_communications = JSON(response.body)['communications']
      response_appointments = response_communications.map { |communication| communication['appointment_id']}.to_set

      # expect(response_communications.count).to eq 10
      # expect(response_facilities).to match_array([request_facility.id, facility_in_same_group.id])
      expect(response_appointments).not_to include(appointment_in_another_group.id)
    end
  end
end
