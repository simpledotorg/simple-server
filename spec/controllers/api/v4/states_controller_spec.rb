# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V4::StatesController, type: :controller do
  describe "#index" do
    it "returns a list of state names" do
      states = %w[Maharashtra Punjab Gujarat]
      states.each { |state| create(:facility, facility_group: create(:facility_group, state: state)) }

      get :index

      expect(JSON.parse(response.body)["states"].map { |state| state["name"] }).to match_array(states)
    end

    it "returns only states that have facilities" do
      state_without_facility = "Madhya Pradesh"
      create(:facility_group, state: state_without_facility)

      get :index

      expect(Region.state_regions.first.name).to eq(state_without_facility)
      expect(JSON.parse(response.body)["states"]).to be_empty
    end
  end
end
