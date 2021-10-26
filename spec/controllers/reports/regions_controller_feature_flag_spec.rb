require "rails_helper"

RSpec.describe Reports::RegionsController, "feature flags", type: :controller do
  let(:organization) { FactoryBot.create(:organization) }
  let(:cvho) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }
  let(:facility_1) { FactoryBot.create(:facility, name: "facility_1", facility_group: facility_group_1) }

  def refresh_views
    RefreshReportingViews.call
  end

  context "reporting schema v2 flag" do
    it "is enabled if v2 param is set" do
      sign_in(create(:admin, :power_user).email_authentication)
      get :show, params: {id: facility_group_1.slug, report_scope: "district", v2: "1"}
      expect(assigns(:repository).reporting_schema_v2?).to be_truthy
      expect(response).to be_successful
      expect(RequestStore[:reporting_schema_v2]).to be_truthy
    end

    it "is disabled if v2 param is not set" do
      sign_in(create(:admin, :power_user).email_authentication)
      get :show, params: {id: facility_group_1.slug, report_scope: "district"}
      expect(assigns(:repository).reporting_schema_v2?).to be_falsey
      expect(response).to be_successful
    end

    it "is enabled if user feature flag is enabled" do
      Flipper.enable(:reporting_schema_v2, cvho)

      sign_in(cvho.email_authentication)
      get :show, params: {id: facility_1.slug, report_scope: "facility"}
      expect(response).to be_successful
      expect(assigns(:repository).reporting_schema_v2?).to be_truthy
    end

    it "is disabled if user feature flag is enabled but v2 flag is false" do
      Flipper.enable(:reporting_schema_v2, cvho)

      sign_in(cvho.email_authentication)
      get :show, params: {id: facility_1.slug, report_scope: "facility", v2: "false"}
      expect(response).to be_successful
      expect(assigns(:repository).reporting_schema_v2?).to be_falsey
    end
  end
end
