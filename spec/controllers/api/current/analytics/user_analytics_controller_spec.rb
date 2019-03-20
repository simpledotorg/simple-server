require 'rails_helper'

RSpec.describe Api::Current::Analytics::UserAnalyticsController, type: :controller do
  render_views

  let!(:request_user) { create(:user) }
  let!(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }

  let!(:patients) { create_list(:patient, 10, registration_facility: request_facility) }

  before :each do
    request.env['HTTP_X_USER_ID'] = request_user.id
    request.env['HTTP_X_FACILITY_ID'] = request_facility.id
    request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
  end

  describe 'GET: send data from server to device;' do
    it 'gets data for 4 weeks as a hashmap' do
      get :show, format: :json

      response_body = JSON(response.body)
      expect(response_body).to be_instance_of(Hash)
    end

    it 'gets html when requested' do
      get :show, format: :html

      expect(response.status).to eq(200)
      expect(response.body).to match(/analytics-container/)
      expect(response.body).to match(/featured-graph/)
    end

    it 'has the facility name' do
      get :show, format: :html

      expect(response.body).to match(Regexp.new(request_facility.name))
    end

    it 'has the patient counts for the facility' do
      get :show, format: :html

      expect(response.body).to match(Regexp.new("#{patients.count} patients"))
    end
  end
end