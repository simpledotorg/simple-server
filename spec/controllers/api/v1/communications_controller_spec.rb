require 'rails_helper'

RSpec.describe Api::V1::CommunicationsController, type: :controller do
  let(:request_user) { FactoryBot.create(:user) }
  before :each do
    request.env['X_USER_ID'] = request_user.id
    request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
  end

  let(:model) { Communication }

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
    it_behaves_like 'a working V1 sync controller sending records'
  end
end
