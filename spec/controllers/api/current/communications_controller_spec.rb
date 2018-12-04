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
end
