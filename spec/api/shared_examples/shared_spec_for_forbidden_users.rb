# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "returns 403 for post requests for forbidden users" do |request_key|
  response "403", "user is not allowed to sync" do
    let(:request_user) do
      user = create(:user)
      user.update(sync_approval_status: :denied)
      user
    end
    let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
    let(:HTTP_X_USER_ID) { request_user.id }
    let(:HTTP_X_FACILITY_ID) { request_facility.id }
    let(:Authorization) { "Bearer #{request_user.access_token}" }

    let(request_key.to_sym) { {request_key => []} }
    run_test!
  end
end

RSpec.shared_examples "returns 403 for get requests for forbidden users" do
  response "403", "user is not allowed to sync" do
    let(:request_user) do
      user = create(:user)
      user.update(sync_approval_status: :denied)
      user
    end

    let(:request_facility) { create(:facility, facility_group: request_user.facility.facility_group) }
    let(:HTTP_X_USER_ID) { request_user.id }
    let(:HTTP_X_FACILITY_ID) { request_facility.id }
    let(:Authorization) { "Bearer #{request_user.access_token}" }

    let(:process_token) { Base64.encode64({other_facilities_processed_since: 10.minutes.ago}.to_json) }
    let(:limit) { 10 }
    run_test!
  end
end
