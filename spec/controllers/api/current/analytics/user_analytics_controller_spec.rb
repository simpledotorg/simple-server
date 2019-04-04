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
    context 'json_api' do
      describe 'facility has no patients registered' do
        it 'returns nil as the response' do
          get :show, format: :json

          response_body = JSON(response.body)
          expect(response_body).to be_nil
        end
      end

      describe 'facility has patients registered' do
        let!(:patients) { create_list(:patient, 2, registration_facility: request_facility) }

        it 'returns the statistics for the facility as json' do
          get :show, format: :json

          response_body = JSON(response.body)
          expect(response_body.keys.map(&:to_sym))
            .to include(:first_of_current_month,
                        :total_patients_count,
                        :unique_patients_per_month,
                        :patients_enrolled_per_month)
        end
      end
    end

    context 'html api' do
      render_views

      describe 'facility has no patients registered' do
        it 'returns an empty graph' do
          get :show, format: :html

          expect(response.status).to eq(200)
          expect(response).to render_template(partial: '_empty_reports')
        end
      end

      describe 'facility has patients registered' do
        let(:months) { (1..6).map { |month| Date.new(2019, month, 1) } }
        let!(:patients) do
          patients = []
          months.each do |week|
            Timecop.scale(1.day, week) { patients << create_list(:patient, 2, registration_facility: request_facility) }
          end
          patients.flatten
        end

        it 'gets html when requested' do
          get :show, format: :html

          expect(response.status).to eq(200)
          expect(response.content_type).to eq('text/html')
        end

        it 'has the name of the current facility' do
          get :show, format: :html

          expect(response.body).to match(Regexp.new(request_facility.name))
        end

        it 'has the total patient counts for the facility' do
          get :show, format: :html

          expect(response.body).to match(/All time/)
          expect(response.body).to match(Regexp.new("#{patients.count}"))
        end
      end
    end
  end
end
