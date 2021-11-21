require "rails_helper"

RSpec.describe Api::V3::Analytics::UserAnalyticsController, type: :controller do
  let!(:request_user) { create(:user) }
  let(:jan_2020) { Time.parse("January 1 2020") }

  describe "#show" do
    let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }

    context "json" do
      render_views

      before :each do
        request.env["HTTP_X_USER_ID"] = request_user.id
        request.env["HTTP_X_FACILITY_ID"] = request_facility.id
        request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
      end

      it "renders statistics for the facility as json" do
        refresh_views

        get :show, format: :json, params: {v2: "0"}

        response_body = JSON.parse(response.body)
        expect(response.status).to eq(200)
        expect(response_body.keys.map(&:to_sym)).to include(:daily, :monthly, :all_time, :trophies, :metadata)

        get :show, format: :json, params: {v2: "1"}

        response_body = JSON.parse(response.body)
        expect(response.status).to eq(200)
        expect(response_body.keys.map(&:to_sym)).to include(:daily, :monthly, :all_time, :trophies, :metadata)
      end
    end

    context "html" do
      render_views

      before :each do
        request.env["HTTP_X_USER_ID"] = request_user.id
        request.env["HTTP_X_FACILITY_ID"] = request_facility.id
        request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
      end

      it "returns cohort data" do
        patients = create_list(:patient, 2, registration_facility: request_facility, registration_user: request_user, recorded_at: jan_2020.advance(months: -2))
        create(:bp_with_encounter, :under_control, recorded_at: jan_2020 + 1.day, patient: patients[0], facility: request_facility)
        create(:bp_with_encounter, :hypertensive, recorded_at: jan_2020 + 1.day, patient: patients[1], facility: request_facility)

        Timecop.freeze("April 15th 2020") do
          refresh_views
          get :show, format: :html
        end
        expect(response.status).to eq(200)

        cohort_data = assigns(:user_analytics).statistics[:cohorts]
        q1_2020 = cohort_data[0]
        expect(q1_2020["period"]).to eq(Period.quarter("Q1-2020"))
        expect(q1_2020["registered"]).to eq(2)
        expect(q1_2020["controlled"]).to eq(1)
        expect(q1_2020["uncontrolled"]).to eq(1)
      end
    end

    context "when diabetes management is enabled" do
      let(:request_facility) {
        create(:facility,
          enable_diabetes_management: true,
          facility_group: request_user.facility.facility_group)
      }

      before :each do
        request.env["HTTP_X_USER_ID"] = request_user.id
        request.env["HTTP_X_FACILITY_ID"] = request_facility.id
        request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
      end

      context "html" do
        render_views

        describe "facility has data" do
          it "renders various important sections in the ui" do
            get :show, format: :html

            expect(response.status).to eq(200)
            expect(response.content_type).to eq("text/html")

            # ui cards
            expect(response.body).to have_content(/Tap "Sync" on the home screen for new data/)
            expect(response.body).to have_content(/Registered/)
            expect(response.body).to have_content(/Follow-up patients/)
            expect(response.body).to have_content(/Hypertension controlled/)
            expect(response.body).to have_content(/Notes/)
          end

          context "achievements" do
            it "has the section visible" do
              request_date = Date.new(2018, 4, 8)

              #
              # create BPs (follow-ups)
              #
              patients = create_list(:patient, 3, registration_facility: request_facility, recorded_at: request_date)
              patients.each do |patient|
                [patient.recorded_at + 1.month,
                  patient.recorded_at + 2.months,
                  patient.recorded_at + 3.months,
                  patient.recorded_at + 4.months].each do |date|
                  travel_to(date) do
                    create(:blood_pressure, :with_encounter, patient: patient, facility: request_facility, user: request_user)
                  end
                end
              end

              get :show, format: :html
              expect(response.body).to match(/Achievements/)
            end

            it "is not visible if there are insufficient follow_ups" do
              get :show, format: :html
              expect(response.body).to_not match(/Achievements/)
            end
          end
        end
      end
    end

    context "when diabetes management is disabled" do
      let(:request_facility) {
        create(:facility,
          enable_diabetes_management: false,
          facility_group: request_user.facility.facility_group)
      }

      before :each do
        request.env["HTTP_X_USER_ID"] = request_user.id
        request.env["HTTP_X_FACILITY_ID"] = request_facility.id
        request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
      end

      context "html" do
        render_views
        it "has the follow-ups card" do
          get :show, format: :html

          expect(response.body).to match(/Follow-up patients/)
        end
      end
    end
  end
end
