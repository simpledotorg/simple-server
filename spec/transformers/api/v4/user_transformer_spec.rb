require 'rails_helper'

RSpec.describe Api::V4::UserTransformer do
  describe 'to_find_response' do
    let!(:user) { create(:user) }
    let(:user_attributes) do
      {
        'id' => '123',
        'sync_approval_status' => 'approved',
        'other' => 'unnecessary',
        'field' => 'values',
        'otp' => '123456',
        'otp_valid_until' => Time.current,
        'access_token' => 'access token string',
        'logged_in_at' => Time.current
      }
    end

    subject(:response) { described_class.to_find_response(user) }

    before do
      allow(described_class).to receive(:to_response)
        .with(user)
        .and_return(user_attributes)
    end

    it 'includes limited params' do
      expect(response).to include(
        'id' => '123',
        'sync_approval_status' => 'approved'
      )
    end

    it 'excludes other params' do
      expect(response).not_to include('other', 'field')
    end

    it 'excludes sensitive params' do
      expect(response).not_to include('otp',
                                      'otp_valid_until',
                                      'access_token',
                                      'logged_in_at',
                                      'role',
                                      'organization_id')
    end
  end
end
