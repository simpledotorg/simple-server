require 'rails_helper'

RSpec.describe Api::V3::Analytics::UserAnalyticsController, type: :controller do
  let!(:request_user) { create(:user) }
  let!(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }

  before :each do
    request.env['HTTP_X_USER_ID'] = request_user.id
    request.env['HTTP_X_FACILITY_ID'] = request_facility.id
    request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
  end

  describe '#show' do
    context 'json' do
      it 'renders statistics for the facility as json' do
        get :show, format: :json
        response_body = JSON.parse(response.body, symbolize_names: true)

        expect(response_body.keys.map(&:to_sym))
          .to include(:daily,
                      :monthly,
                      :all_time,
                      :trophies,
                      :metadata)
      end
    end

    context 'html' do
      render_views

      describe 'facility has data' do
        it 'gets html when requested' do
          get :show, format: :html

          expect(response.status).to eq(200)
          expect(response.content_type).to eq('text/html')
        end

        it 'has the sync nudge card' do
          get :show, format: :html

          expect(response.body).to match(/Tap "Sync" on the home screen for new data/)
        end


        it 'has the registrations card' do
          get :show, format: :html

          expect(response.body).to match(/Registered/)
        end

        it 'has the follow-ups card' do
          get :show, format: :html

          expect(response.body).to match(/Follow-up hypertension patients/)
        end

        it 'has the hypertension control card' do
          get :show, format: :html

          expect(response.body).to match(/Hypertension control/)
        end

        context 'achievements' do
          it 'has the section visible' do
            Timecop.freeze("10:00 AM UTC") do
              #
              # create BPs (follow-ups)
              #
              patients = create_list(:patient, 3, registration_facility: request_facility)
              patients.each do |patient|
                [patient.recorded_at + 1.month,
                patient.recorded_at + 2.months,
                patient.recorded_at + 3.months,
                patient.recorded_at + 4.months].each do |date|
                  travel_to(date) do
                    create(:encounter,
                          :with_observables,
                          observable: create(:blood_pressure,
                                              patient: patient,
                                              facility: request_facility,
                                              user: request_user))
                  end
                end
              end

              get :show, format: :html
              expect(response.body).to match(/Achievements/)
            end
          end

          it 'is not visible if there are insufficient follow_ups' do
            get :show, format: :html
            expect(response.body).to_not match(/Achievements/)
          end
        end

        it 'has the footer' do
          get :show, format: :html

          expect(response.body).to match(/Notes/)
        end
      end
    end
  end

  context 'legacy progress tabs' do
    before do
      allow(FeatureToggle).to receive(:enabled?).with('NEW_PROGRESS_TAB').and_return(false)
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
                          :follow_up_patients_per_month,
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

          it 'has the name of the v3 facility' do
            get :show, format: :html

            expect(response.body).to match(Regexp.new(request_facility.name))
          end

          it 'has the total patient counts for the facility' do
            get :show, format: :html

            expect(response.body).to match(/All time/)
            expect(response.body).to match(Regexp.new(patients.count.to_s))
          end
        end
      end
    end
  end
end
