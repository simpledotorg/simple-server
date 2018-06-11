require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do
  let(:model) { User }

  let(:build_payload) { lambda { build_user_payload } }
  let(:build_invalid_payload) { lambda { build_invalid_user_payload } }
  let(:invalid_record) { build_invalid_payload.call }
  let(:update_payload) { lambda { |user| updated_user_payload user } }
  let(:number_of_schema_errors_in_invalid_payload) { 2 }

  describe 'POST sync: send data from device to server;' do
    it_behaves_like 'a working sync controller creating records'
    it_behaves_like 'a working sync controller updating records'
  end

  describe 'GET sync: send data from server to device;' do
    it_behaves_like 'a working sync controller sending records'
  end
end
