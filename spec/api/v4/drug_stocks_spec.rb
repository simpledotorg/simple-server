require "swagger_helper"

describe "Drug Stocks v4 API", swagger_doc: "v4/swagger.json" do
  path "/drug_stocks" do
    get "Request the drug stock report for a given month at your facility" do
      tags "Drug stock"
      security [access_token: [], user_id: [], facility_id: []]
      parameter name: "HTTP_X_USER_ID", in: :header, type: :uuid
      parameter name: "HTTP_X_FACILITY_ID", in: :header, type: :uuid
      parameter name: :date, in: :query, type: :date, description: "Any date in the requested month - eg. 2021-10-29"

      response "200", "Drug stocks are returned" do
        let(:date) { "2021-10-29" }
        let(:request_user) { create(:user) }
        let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }
        before do
          create(
            :drug_stock,
            facility: request_facility,
            for_end_of_month: Date.new(2021, 10, 31)
          )
        end

        schema Api::V4::Schema.drug_stocks_response
        run_test!
      end

      response "404", "No drug stock report has been submitted for the specified month" do
        let(:date) { "2021-08-30" }
        let(:request_user) { create(:user) }
        let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        run_test!
      end
    end
  end
end
