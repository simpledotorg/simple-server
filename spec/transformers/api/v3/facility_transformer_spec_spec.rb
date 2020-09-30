require "rails_helper"

RSpec.describe Api::V3::FacilityTransformer do
  describe ".to_response" do
    let(:facility) { FactoryBot.build(:facility) }

    it "sets the sync_group_id to the facility's zone" do
      transformed_facility = Api::V3::FacilityTransformer.to_response(facility)
      expect(transformed_facility[:sync_group_id]).to eq facility.zone
    end
  end
end
