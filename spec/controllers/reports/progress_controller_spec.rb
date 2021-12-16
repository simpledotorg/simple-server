require "rails_helper"

RSpec.describe Reports::ProgressController, type: :controller do
  let(:organization) { FactoryBot.create(:organization) }
  let(:cvho) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }
  let(:facility_1) { FactoryBot.create(:facility, name: "facility_1", facility_group: facility_group_1) }

  describe "show" do
    render_views

    context "access denied" do
      it "restricts access if feature flag is not enabled" do
        Flipper.disable(:dashboard_progress_reports)
        sign_in(cvho.email_authentication)

        get :show, params: {id: facility_1.slug}
        expect(response).to be_redirect
        expect(response).to redirect_to(root_url)
      end

      it "redirects if user does not have proper access to org" do
        district_official = create(:admin, :viewer_reports_only, :with_access, resource: create(:facility_group))
        sign_in(district_official.email_authentication)

        get :show, params: {id: facility_1.slug}
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
        expect(response).to be_redirect
      end
    end

    it "renders successfully if feature flag is enabled" do
      cvho.enable_feature(:dashboard_progress_reports)
      sign_in(cvho.email_authentication)

      get :show, params: {id: facility_1.slug}
      expect(response).to be_successful
    end

    it "does not render drug stock form (regardless of feature flag)" do
      Flipper.enable(:drug_stocks, facility_1.facility_group.region)
      get :show, params: {id: facility_1.slug}
      expect(response.body).to_not include("Submit Drug Stock")
    end
  end
end
