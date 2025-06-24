require "rails_helper"

def login_user
  # @request.env["devise.mapping"] = Devise.mappings[:admin]
  admin = FactoryBot.create(:admin, :power_user)
  # admin = create(:admin, :manager, :with_access, resource: facility_group)
  sign_in admin.email_authentication
end

RSpec.describe DrRai::ActionPlansController, type: :controller do
  # TODO: Complete this suite — DrRai::Indicators Request Spec

  let(:district_with_facilities) { setup_district_with_facilities }
  let(:region) { district_with_facilities[:region] }
  let(:facility_1) { district_with_facilities[:facility_1] }

  let(:valid_attributes) {
    {
      actions: "",
      indicator_id: "",
      period: "Q2-2025",
      region_slug: region.slug,
      statement: "Must be completed before tomorrow",
      target_type: "DrRai::PercentageTarget",
      target_value: 12
    }
  }

  let(:invalid_attributes) {
    {
      actions: "",
      indicator_id: "",
      period: "Q2-2025",
      region_slug: region.slug,
      # Action Plans need #statement
      # statement: "Must be completed before tomorrow",
      target_type: "DrRai::PercentageTarget",
      target_value: 12
    }
  }

  before do
    login_user
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new DrRai::ActionPlan" do
        expect {
          post dr_rai_action_plans_url, params: {dr_rai_action_plan: valid_attributes}
        }.to change(DrRai::ActionPlan, :count).by(1)
      end

      it "redirects to the created dr_rai_action_plan" do
        post dr_rai_action_plans_url, params: {dr_rai_action_plan: valid_attributes}
        expect(response).to redirect_to(reports_regions_path(report_scope: "facility", id: valid_attributes[:region_slug]))
      end
    end

    context "with invalid parameters" do
      it "does not create a new DrRai::ActionPlan" do
        expect {
          post :create, params: {dr_rai_action_plan: invalid_attributes}
        }.to change(DrRai::ActionPlan, :count).by(0)
      end

      it "renders a successful response (i.e. to display the 'new' template)" do
        post dr_rai_action_plans_url, params: {dr_rai_action_plan: invalid_attributes}
        expect(response).to be_successful
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested dr_rai_action_plan" do
      DrRai::ActionPlan.create! valid_attributes
      expect {
        delete dr_rai_action_plan_url(dr_rai_action_plan)
      }.to change(DrRai::ActionPlan, :count).by(-1)
    end

    it "redirects to the dr_rai_action_plans list" do
      DrRai::ActionPlan.create! valid_attributes
      delete dr_rai_action_plan_url(dr_rai_action_plan)
      expect(response).to redirect_to(dr_rai_action_plans_url)
    end
  end
end
