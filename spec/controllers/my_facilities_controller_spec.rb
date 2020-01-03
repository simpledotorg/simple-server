require 'rails_helper'

RSpec.describe MyFacilitiesController, type: :controller do
  let(:facility_group) { create(:facility_group) }
  let(:supervisor) { create(:admin, :supervisor, facility_group: facility_group) }

  before do
    sign_in(supervisor.email_authentication)
  end

  describe 'GET #index' do
    render_views

    it 'returns a success response' do
      get :index, params: {}

      expect(response).to be_success
    end

    it 'returns a success response' do
      get :ranked_facilities, params: {}

      expect(response).to be_success
    end

    it 'returns a success response' do
      get :blood_pressure_control, params: {}

      expect(response).to be_success
    end

    it 'returns a success response' do
      get :registrations, params: {}

      expect(response).to be_success
    end
  end
end
