require 'swagger_helper'

describe 'Users API' do

  path '/users/sync' do

    post 'Syncs user data from device to server.' do
      tags 'User'
      parameter name: :users, in: :body, schema: Api::V1::Schema.user_sync_from_user_request

      response '200', 'users created' do
        let(:users) { { users: (1..10).map { build_user_payload } } }
        run_test!
      end

      response '200', 'some, or no errors were found' do
        schema Api::V1::Schema.sync_from_user_errors
        let(:users) { { users: (1..10).map { build_invalid_user_payload } } }
        run_test!
      end
    end

    get 'Syncs user data from server to device.' do
      tags 'User'
      Api::V1::Schema.sync_to_user_request.each do |param|
        parameter param
      end

      before :each do
        Timecop.travel(10.minutes.ago) do
          FactoryBot.create_list(:user, 5)
          FactoryBot.create_list(:user_created_on_device, 5)
        end
      end

      response '200', 'users received' do
        schema Api::V1::Schema.user_sync_to_user_response
        let(:processed_since) { 10.minutes.ago }
        let(:limit) { 10 }
        run_test!
      end
    end
  end
end