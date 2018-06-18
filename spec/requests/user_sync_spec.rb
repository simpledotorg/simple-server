require 'rails_helper'

RSpec.describe 'Users sync', type: :request do
  let(:sync_route) { '/api/v1/users/sync' }

  let(:model) { User }

  let(:build_payload) { lambda { build_user_payload } }
  let(:build_invalid_payload) { lambda { build_invalid_user_payload } }
  let(:update_payload) { lambda { |user| updated_user_payload user } }
  let(:keys_not_expected_in_response) { %i[otp otp_valid_until] }

  def to_response(user)
    Api::V1::UserTransformer.to_response(user)
  end

  include_examples 'sync requests'
end
