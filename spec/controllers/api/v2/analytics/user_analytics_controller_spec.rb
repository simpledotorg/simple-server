require 'rails_helper'

RSpec.describe Api::V2::Analytics::UserAnalyticsController, type: :controller do
  let!(:request_user) { create(:user) }
  let!(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }

  before :each do
    request.env['HTTP_X_USER_ID'] = request_user.id
    request.env['HTTP_X_FACILITY_ID'] = request_facility.id
    request.env['HTTP_AUTHORIZATION'] = "Bearer #{request_user.access_token}"
  end

  describe '#show' do
    context 'json' do
      describe 'facility has data' do
        it 'has the statistics for the facility as json' do
          get :show, format: :json
          response_body = JSON.parse(response.body, symbolize_names: true)

          expect(response_body.keys.map(&:to_sym))
            .to include(:daily,
                        :monthly,
                        :all_time,
                        :trophies,
                        :metadata)
        end

        context 'daily' do
          let(:request_date) { Date.new(2018, 1, 1) }
          let(:reg_date) { request_date - 3.days }
          let(:follow_up_date) { request_date - 2.days }

          before do
            patients = create_list(:patient, 3, registration_facility: request_facility, recorded_at: reg_date)
            patients.each do |patient|
              create(:blood_pressure,
                     patient: patient,
                     facility: request_facility,
                     user: request_user,
                     recorded_at: follow_up_date)
            end

            LatestBloodPressuresPerPatientPerDay.refresh

            stub_const("Api::V3::Analytics::UserAnalyticsController::DAYS_AGO", 6)
          end

          it 'has data grouped by date' do
            response_body =
              travel_to(request_date) do
                get :show, format: :json
                JSON.parse(response.body, symbolize_names: true)
              end

            expected_output = {
              registrations: {
                (request_date - 5.days).to_s => 0,
                (request_date - 4.days).to_s => 0,
                reg_date.to_date.to_s => 3,
                (request_date - 2.days).to_s => 0,
                (request_date - 1.days).to_s => 0,
                request_date.to_s => 0,
              },

              follow_ups: {
                (request_date - 5.days).to_s => 0,
                (request_date - 4.days).to_s => 0,
                (request_date - 3.days).to_s => 0,
                follow_up_date.to_date.to_s => 3,
                (request_date - 1.days).to_s => 0,
                request_date.to_s => 0,
              }
            }

            expect(response_body.dig(:daily, :grouped_by_date)).to eq(expected_output.deep_symbolize_keys)
          end

          it 'has no data if facility has not recorded anything recently' do
            get :show, format: :json
            response_body = JSON.parse(response.body, symbolize_names: true)

            expected_output = {
              registrations: {
                (Date.today - 5).to_s => 0,
                (Date.today - 4).to_s => 0,
                (Date.today - 3).to_s => 0,
                (Date.today - 2).to_s => 0,
                (Date.today - 1).to_s => 0,
                Date.today.to_s => 0
              },

              follow_ups: {
                (Date.today - 5).to_s => 0,
                (Date.today - 4).to_s => 0,
                (Date.today - 3).to_s => 0,
                (Date.today - 2).to_s => 0,
                (Date.today - 1).to_s => 0,
                Date.today.to_s => 0,
              }
            }

            expect(response_body.dig(:daily, :grouped_by_date)).to eq(expected_output.deep_symbolize_keys)
          end
        end

        context 'monthly' do
          let(:request_date) { Date.new(2018, 1, 1) }
          let(:reg_date) { request_date - 3.months }
          let(:follow_up_date) { request_date - 2.months }
          let(:controlled_follow_up_date) { request_date - 1.month }
          let(:gender) { 'female' }

          before do
            patients = create_list(:patient,
                                   3,
                                   registration_facility: request_facility,
                                   recorded_at: reg_date,
                                   gender: gender)
            patients.each do |patient|
              create(:blood_pressure,
                     :critical,
                     patient: patient,
                     facility: request_facility,
                     user: request_user,
                     recorded_at: follow_up_date)

              create(:blood_pressure,
                     :under_control,
                     patient: patient,
                     facility: request_facility,
                     user: request_user,
                     recorded_at: controlled_follow_up_date)
            end

            LatestBloodPressuresPerPatientPerDay.refresh

            stub_const("Api::V3::Analytics::UserAnalyticsController::MONTHS_AGO", 6)
          end

          it 'has data grouped by date and gender' do
            response_body =
              travel_to(request_date) do
                get :show, format: :json
                JSON.parse(response.body, symbolize_names: true)
              end

            expected_output = {
              registrations: {
                gender => {
                  (request_date - 5.months).to_s => 0,
                  (request_date - 4.months).to_s => 0,
                  reg_date.to_date.to_s => 3,
                  (request_date - 2.months).to_s => 0,
                  controlled_follow_up_date.to_date.to_s => 0,
                  request_date.to_s => 0,
                }
              },

              follow_ups: {
                gender => {
                  (request_date - 5.months).to_s => 0,
                  (request_date - 4.months).to_s => 0,
                  (request_date - 3.months).to_s => 0,
                  follow_up_date.to_date.to_s => 3,
                  controlled_follow_up_date.to_date.to_s => 3,
                  request_date.to_s => 0,
                }
              }
            }

            expect(response_body.dig(:monthly, :grouped_by_gender_and_date)).to eq(expected_output.deep_symbolize_keys)
          end

          it 'has data grouped by date' do
            response_body =
              travel_to(request_date) do
                get :show, format: :json
                JSON.parse(response.body, symbolize_names: true)
              end

            expected_output = {
              total_visits: {
                (request_date - 5.months).to_s => 0,
                (request_date - 4.months).to_s => 0,
                (request_date - 3.months).to_s => 0,
                (request_date - 2.months).to_s => 3,
                (request_date - 1.months).to_s => 3,
                request_date.to_s => 0,
              },

              controlled_visits: {
                (request_date - 5.months).to_s => 0,
                (request_date - 4.months).to_s => 0,
                (request_date - 3.months).to_s => 0,
                (request_date - 2.months).to_s => 0,
                (request_date - 1.months).to_s => 3,
                request_date.to_s => 0,
              }
            }

            expect(response_body.dig(:monthly, :grouped_by_date)).to eq(expected_output.deep_symbolize_keys)
          end

          it 'has no data if facility has not recorded anything recently' do
            get :show, format: :json
            response_body = JSON.parse(response.body, symbolize_names: true)

            expected_output =
              {
                follow_ups: {},
                registrations: {}
              }
            expect(response_body.dig(:monthly, :grouped_by_gender_and_date)).to eq(expected_output)
          end
        end

        context 'all_time' do
          let(:request_date) { Date.new(2018, 1, 1) }
          let(:reg_date) { request_date - 3.months }
          let(:follow_up_date) { request_date - 2.months }
          let(:gender) { 'female' }

          before do
            patients = create_list(:patient,
                                   3,
                                   registration_facility: request_facility,
                                   recorded_at: reg_date,
                                   gender: gender)
            patients.each do |patient|
              create(:blood_pressure,
                     patient: patient,
                     facility: request_facility,
                     user: request_user,
                     recorded_at: follow_up_date)
            end

            LatestBloodPressuresPerPatientPerDay.refresh
          end

          it 'has data grouped by gender' do
            get :show, format: :json
            response_body = JSON.parse(response.body, symbolize_names: true)

            expected_output = {
              follow_ups: {
                gender => 3
              },

              registrations: {
                gender => 3
              }
            }

            expect(response_body.dig(:all_time, :grouped_by_gender)).to eq(expected_output.deep_symbolize_keys)
          end
        end

        context 'metadata' do
          context 'last_updated_at' do
            it 'has date for today if request was made today' do
              get :show, format: :json
              response_body = JSON.parse(response.body, symbolize_names: true)

              expect(response_body.dig(:metadata, :last_updated_at).to_date)
                .to eq(Time.current.to_date)
            end

            it 'has the date at which the request was made' do
              two_days_ago = 2.days.ago.to_date

              response_body = travel_to(two_days_ago) do
                get :show, format: :json
                JSON.parse(response.body, symbolize_names: true)
              end

              expect(response_body.dig(:metadata, :last_updated_at).to_date)
                .to eq(two_days_ago)
            end
          end

          it 'has the formatted_today_string (in the correct locale)' do
            current_locale = I18n.locale

            I18n.available_locales.each do |locale|
              I18n.locale = locale

              get :show, format: :json
              response_body = JSON.parse(response.body, symbolize_names: true)

              expect(response_body.dig(:metadata, :formatted_today_string))
                .to eq(I18n.t(:today_str))
            end

            # reset locale
            I18n.locale = current_locale
          end

          it 'has the formatted_next_date' do
            date = Date.new(2020, 1, 1)

            response_body = travel_to(date) do
              get :show, format: :json
              JSON.parse(response.body, symbolize_names: true)
            end

            expect(response_body.dig(:metadata, :formatted_next_date))
              .to eq('02-JAN-2020')
          end
        end

        context 'trophies' do
          it 'has both unlocked and the upcoming locked trophy' do
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
                  create(:blood_pressure,
                         patient: patient,
                         facility: request_facility,
                         user: request_user)
                end
              end
            end

            LatestBloodPressuresPerPatientPerDay.refresh

            get :show, format: :json
            response_body = JSON.parse(response.body, symbolize_names: true)

            expected_output = {
              locked_trophy_value: 25,
              unlocked_trophy_values: [10]
            }.with_indifferent_access

            expect(response_body[:trophies]).to eq(expected_output.deep_symbolize_keys)
          end

          it 'has only 1 locked trophy if there are no achievements' do
            get :show, format: :json
            response_body = JSON.parse(response.body, symbolize_names: true)

            expected_output = {
              locked_trophy_value: 10,
              unlocked_trophy_values: []
            }.with_indifferent_access

            expect(response_body[:trophies]).to eq(expected_output.deep_symbolize_keys)
          end
        end
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

        it 'has the achievements section' do
          get :show, format: :html

          expect(response.body).to match(/Achievements/)
        end

        it 'has the footer' do
          get :show, format: :html

          expect(response.body).to match(/Notes/)
        end
      end
    end
  end
end
