require "rails_helper"

RSpec.describe Api::V3::ProtocolsController, type: :controller do
  describe "GET sync: send data from server to device;" do
    context "for authenticated requests" do
      def set_authentication_headers
        request.env["HTTP_X_USER_ID"] = request_user.id
        request.env["HTTP_X_FACILITY_ID"] = request_facility.id if defined? request_facility
        request.env["HTTP_AUTHORIZATION"] = "Bearer #{request_user.access_token}"
        request.env["HTTP_X_SYNC_REGION_ID"] = request_facility.region.block_region.id
      end

      let(:request_user) { create(:user) }
      let(:request_facility_group) { request_user.facility.facility_group }
      let(:request_facility) { create(:facility, facility_group: request_facility_group) }

      before do
        set_authentication_headers
      end

      it "avoids resyncing when X_SYNC_REGION_ID doesn't match process token's sync_region_id" do
        process_token = make_process_token(sync_region_id: "a-sync-region-uuid",
          other_facilities_processed_since: Time.current)
        protocol_records = Timecop.travel(15.minutes.ago) { create_list(:protocol, 5) }

        get :sync_to_user, params: {process_token: process_token}

        response_record_ids = JSON(response.body)["protocols"].map { |r| r["id"] }
        expect(response_record_ids).not_to include(*protocol_records.map(&:id))
      end
    end
  end
end
