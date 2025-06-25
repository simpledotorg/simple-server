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
  let(:indicator) { create(:indicator, :contact_overdue_patients) }

  let(:valid_attributes) {
    {
      actions: "",
      indicator_id: indicator.id,
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

  let(:district_with_facilities) { setup_district_with_facilities }
  let(:region) { district_with_facilities[:region] }

  before do
    login_user
    DrRai::Indicator.with_discarded.delete_all
    DrRai::Target.with_discarded.delete_all
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new DrRai::ActionPlan" do
        expect {
          post :create, params: {dr_rai_action_plan: valid_attributes}
        }.to change(DrRai::ActionPlan, :count).by(1)
      end

      it "redirects to the facility" do
        post :create, params: {dr_rai_action_plan: valid_attributes}
        expect(response).to redirect_to(reports_region_path(report_scope: "facility", id: valid_attributes[:region_slug]))
      end
    end

    context "with invalid parameters" do
      it "does not create a new DrRai::ActionPlan" do
        expect {
          post :create, params: {dr_rai_action_plan: invalid_attributes}
        }.to raise_error
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested dr_rai_action_plan" do
      dr_rai_action_plan = create :action_plan, region: region, dr_rai_indicator: contact_overdue_patients_indicator
      expect {
        delete :destroy, params: {id: dr_rai_action_plan.to_param}
      }.to change(DrRai::ActionPlan, :count).by(-1)
    end

    it "redirects to the region" do
      dr_rai_action_plan = create :action_plan, region: region, dr_rai_indicator: contact_overdue_patients_indicator
      delete :destroy, params: {id: dr_rai_action_plan.to_param}
      expect(response).to redirect_to(reports_region_path(report_scope: "facility", id: dr_rai_action_plan.region.slug))
    end
  end
end
