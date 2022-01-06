# frozen_string_literal: true

require "swagger_helper"

describe "Analytics Current API", swagger_doc: "v3/swagger.json" do
  path "/analytics/user_analytics" do
    get "Sends JSON containing analytics for User" do
      tags "analytics"
      security [access_token: [], user_id: [], facility_id: []]
      produces "application/json"
      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid

      before :each do
        4.times do |w|
          Timecop.travel(w.weeks.ago) do
            FactoryBot.create_list(:patient, 3)
          end
        end
      end

      response "200", "JSON received" do
        let(:request_user) { FactoryBot.create(:user) }
        let(:request_facility) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }
        let(:Accept) { "text/html" }

        run_test!
      end

      include_examples "returns 403 for get requests for forbidden users"
    end
  end

  path "/analytics/user_analytics.html" do
    get "Sends a static HTML containing analytics for user" do
      tags "analytics"
      security [access_token: [], user_id: [], facility_id: []]
      produces "text/html"
      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid

      before :each do
        4.times do |w|
          Timecop.travel(w.weeks.ago) do
            FactoryBot.create_list(:patient, 3)
          end
        end
      end

      response "200", "HTML received" do
        let(:request_user) { FactoryBot.create(:user) }
        let(:request_facility) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }
        let(:Accept) { "text/html" }

        run_test!
      end

      include_examples "returns 403 for get requests for forbidden users"
    end
  end
end
