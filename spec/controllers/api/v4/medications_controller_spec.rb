# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V4::MedicationsController, type: :controller do
  describe "GET sync: send data from server to device;" do
    model = Medication
    response_key = model.to_s.underscore.pluralize

    it "Returns records from the beginning of time, when process_token is not set" do
      get :sync_to_user
      response_body = JSON(response.body)
      expect(response_body[response_key].count).to eq model.count
      expect(response_body[response_key].map { |record| record["id"] }.to_set)
        .to eq(model.all.pluck(:id).to_set)
    end

    it "Returns records from the beginning of time, even when process_token is set" do
      get :sync_to_user, params: {process_token: make_process_token(other_facilities_processed_since: 10.minutes.ago)}
      response_body = JSON(response.body)
      expect(response_body[response_key].count).to eq model.count
      expect(response_body[response_key].map { |record| record["id"] }.to_set)
        .to eq(model.all.pluck(:id).to_set)
    end

    describe "batching" do
      it "ignores limit param, returns all records" do
        get :sync_to_user, params: {limit: 2}
        response_body = JSON(response.body)
        expect(response_body[response_key].count).to eq model.count
      end
    end
  end
end
