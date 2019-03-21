require 'rails_helper'

RSpec.describe Api::Current::Analytics::UserAnalyticsController, type: :controller do
  let!(:request_user) { create(:user) }
  let!(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }

  before :each do
    request.env['HTTP_X_USER_ID'] = request_user.id
    request.env['HTTP_X_FACILITY_ID'] = request_facility.id
    request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
  end

  describe '#show' do
    context 'html api' do
      render_views

      describe 'facility has no patients registered' do
        it 'returns an empty graph' do

        end
      end

      describe 'facility has patients registered' do
        let(:weeks) { (Date.new(2018, 1, 1)..Date.new(2019, 1, 1)).select(&:sunday?) }
        let!(:patients) do
          patients = []
          weeks.each do |week|
            Timecop.scale(1.day, week) { patients << create_list(:patient, 2, registration_facility: request_facility)}
          end
          patients.flatten
        end

        it 'gets html when requested' do
          get :show, format: :html

          expect(response.status).to eq(200)
          expect(response.body).to match(/card/)
          expect(response.body).to match(/bar-chart/)
        end

        it 'has the name of the current facility' do
          get :show, format: :html

          expect(response.body).to match(Regexp.new(request_facility.name))
        end

        it 'has the total patient counts for the facility' do
          get :show, format: :html

          expect(response.body).to match(/Total enrolled/)
          expect(response.body).to match(Regexp.new("#{patients.count} patients"))
        end
      end
    end
  end

  describe 'GET: send data from server to device;' do
    it 'gets data for 4 weeks as a hashmap' do
      get :show, format: :json

      response_body = JSON(response.body)
      expect(response_body).to be_instance_of(Hash)
    end
  end
end