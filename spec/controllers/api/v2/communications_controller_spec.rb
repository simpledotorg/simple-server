require 'rails_helper'

RSpec.describe Api::V2::CommunicationsController, type: :controller do
  let(:request_user) { create(:master_user, :with_phone_number_authentication) }
  let(:request_facility) { request_user.registration_facility }
  before :each do
    request.env['X_USER_ID'] = request_user.id
    request.env['X_FACILITY_ID'] = request_facility.id
    request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
  end

  let(:model) { Communication }
  let(:build_payload) { lambda { build_communication_payload } }

  it_behaves_like 'a sync controller that authenticates user requests'
  it_behaves_like 'a working sync controller that short circuits disabled apis'

  describe 'POST sync: send data from device to server;' do
  end

  describe 'GET sync: send data from server to device;' do
  end
end
