require "rails_helper"

RSpec.describe Reports::ProgressController, type: :controller do
  let(:jan_2020) { Time.parse("January 1 2020") }
  let(:dec_2019_period) { Period.month(Date.parse("December 2019")) }
  let(:organization) { FactoryBot.create(:organization) }
  let(:cvho) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:call_center_user) { create(:admin, :call_center, full_name: "call_center") }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }
  let(:facility_1) { FactoryBot.create(:facility, name: "facility_1", facility_group: facility_group_1) }

  describe "show" do
    render_views

    before do
      @facility_group = create(:facility_group, organization: organization)
      @facility = create(:facility, name: "CHC Barnagar", facility_group: @facility_group)
      @facility_region = @facility.region
    end

    it "restricts access if feature flag is not enabled" do
      sign_in(cvho.email_authentication)

      get :show, params: {id: facility_1.slug }
      expect(response).to be_redirect
      expect(response).to redirect_to(root_url)
    end

    it "redirects if user does not have proper access to org" do
      district_official = create(:admin, :viewer_reports_only, :with_access, resource: @facility_group)
      sign_in(district_official.email_authentication)

      get :show, params: {id: facility_1.slug }
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      expect(response).to be_redirect
    end

    it "renders successfully if report viewer has access to region and feature flag is on" do
      other_fg = create(:facility_group, name: "other facility group", organization: organization)
      facility = create(:facility, name: "other facility", facility_group: other_fg)
      user = create(:admin, :viewer_reports_only, :with_access, resource: other_fg)
      user.enable_feature(:dashboard_progress_report)
      sign_in(user.email_authentication)
      get :show, params: {id: facility.region.slug}
      expect(response).to be_successful
    end

  end
end