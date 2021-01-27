require "rails_helper"

RSpec::Matchers.define :facilities do |facilities|
  match { |actual| actual.map(&:id) == facilities.map(&:id) }
end

RSpec.describe MyFacilitiesController, type: :controller do
  let(:facility_group) { create(:facility_group) }
  let(:supervisor) { create(:admin, :manager, :with_access, resource: facility_group) }

  render_views

  before do
    sign_in(supervisor.email_authentication)
  end

  describe "GET #index" do
    it "returns a success response" do
      create(:facility, facility_group: facility_group)

      get :index, params: {}

      expect(response).to be_successful
    end
  end

  describe "GET #bp_controlled" do
    it "returns a success response" do
      create(:facility, facility_group: facility_group)

      get :bp_controlled, params: {}

      expect(response).to be_successful
    end
  end

  describe "GET #bp_not_controlled" do
    it "returns a success response" do
      create(:facility, facility_group: facility_group)

      get :bp_not_controlled, params: {}

      expect(response).to be_successful
    end
  end

  describe "GET #missed_visits" do
    it "returns a success response" do
      create(:facility, facility_group: facility_group)

      get :missed_visits, params: {}

      expect(response).to be_successful
    end
  end
end
