require "rails_helper"

RSpec::Matchers.define :facilities do |facilities|
  match { |actual| actual.map(&:id) == facilities.map(&:id) }
end

RSpec.describe MyFacilities::FacilityPerformanceController, type: :controller do
  let(:facility_group) { create(:facility_group) }
  let!(:facilities) { create_list(:facility, 3, facility_group: facility_group) }
  let(:supervisor) { create(:admin, :manager, :with_access, resource: facility_group) }

  render_views

  before do
    sign_in(supervisor.email_authentication)
    Flipper.enable(:ranked_facilities)
  end

  after do
    Flipper.disable(:ranked_facilities)
  end

  describe "GET #show" do
    it "returns a success response" do
      create(:facility, facility_group: facility_group)

      get :show, params: {}

      expect(response).to be_successful
    end
  end
end
