require "rails_helper"

def login_user
  # @request.env["devise.mapping"] = Devise.mappings[:admin]
  admin = FactoryBot.create(:admin, :power_user)
  # admin = create(:admin, :manager, :with_access, resource: facility_group)
  sign_in admin.email_authentication
end

RSpec.describe DrRai::ActionPlansController, type: :controller do
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

  describe "PATCH /update" do
    let(:dr_rai_action_plan) {
      create(:action_plan,
        region: facility_1.region,
        dr_rai_indicator: indicator,
        dr_rai_target: create(:target, :percentage, period: "Q2-2025", indicator: indicator),
        statement: "Original statement",
        actions: "Original actions")
    }

    around do |example|
      Timecop.freeze(Time.zone.parse("April 30 2025 15:12")) { example.run }
    end

    context "authorization" do
      it "allows an admin with report access to the action plan facility to update it" do
        admin = create(:admin, :viewer_reports_only, :with_access, resource: facility_1)
        sign_in admin.email_authentication

        patch :update, params: {
          id: dr_rai_action_plan.to_param,
          dr_rai_action_plan: {actions: "Updated actions"}
        }

        expect(dr_rai_action_plan.reload.actions).to eq("Updated actions")
      end

      it "does not allow an admin without report access to the action plan facility to update it" do
        inaccessible_facility = create(:facility)
        admin = create(:admin, :viewer_reports_only, :with_access, resource: inaccessible_facility)
        sign_in admin.email_authentication

        patch :update, params: {
          id: dr_rai_action_plan.to_param,
          dr_rai_action_plan: {actions: "Updated actions"}
        }

        expect(dr_rai_action_plan.reload.actions).to eq("Original actions")
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    context "within the business edit window" do
      it "allows updates on the last day of the current quarter's first month" do
        patch :update, params: {
          id: dr_rai_action_plan.to_param,
          dr_rai_action_plan: {actions: "Updated actions"}
        }

        expect(response).to have_http_status(:no_content)
        expect(dr_rai_action_plan.reload.actions).to eq("Updated actions")
      end

      it "allows updates during the current quarter's second month" do
        Timecop.freeze(Time.zone.parse("May 1 2025 00:00")) do
          patch :update, params: {
            id: dr_rai_action_plan.to_param,
            dr_rai_action_plan: {actions: "Updated actions"}
          }
        end

        expect(response).to have_http_status(:no_content)
        expect(dr_rai_action_plan.reload.actions).to eq("Updated actions")
      end

      it "forbids updates during the current quarter's last month" do
        Timecop.freeze(Time.zone.parse("June 1 2025 00:00")) do
          patch :update, params: {
            id: dr_rai_action_plan.to_param,
            dr_rai_action_plan: {actions: "Updated actions"}
          }
        end

        expect(response).to have_http_status(:forbidden)
        expect(dr_rai_action_plan.reload.actions).to eq("Original actions")
      end

      it "forbids updates to an action plan targeting another quarter" do
        dr_rai_action_plan.target.update!(period: "Q1-2025")

        patch :update, params: {
          id: dr_rai_action_plan.to_param,
          dr_rai_action_plan: {actions: "Updated actions"}
        }

        expect(response).to have_http_status(:forbidden)
        expect(dr_rai_action_plan.reload.actions).to eq("Original actions")
      end
    end

    context "with the dr_rai_manual_edit override enabled" do
      it "allows updates outside the business edit window" do
        Flipper.enable(:dr_rai_manual_edit)

        Timecop.freeze(Time.zone.parse("June 15 2025 00:00")) do
          patch :update, params: {
            id: dr_rai_action_plan.to_param,
            dr_rai_action_plan: {actions: "Updated actions"}
          }
        end

        expect(response).to have_http_status(:no_content)
        expect(dr_rai_action_plan.reload.actions).to eq("Updated actions")
      ensure
        Flipper.disable(:dr_rai_manual_edit)
      end

      it "allows updates to an action plan targeting another quarter" do
        Flipper.enable(:dr_rai_manual_edit)
        dr_rai_action_plan.target.update!(period: "Q1-2025")

        patch :update, params: {
          id: dr_rai_action_plan.to_param,
          dr_rai_action_plan: {actions: "Updated actions"}
        }

        expect(response).to have_http_status(:no_content)
        expect(dr_rai_action_plan.reload.actions).to eq("Updated actions")
      ensure
        Flipper.disable(:dr_rai_manual_edit)
      end
    end

    it "updates the action plan actions" do
      patch :update, params: {
        id: dr_rai_action_plan.to_param,
        dr_rai_action_plan: {actions: "Updated actions"}
      }

      expect(dr_rai_action_plan.reload.actions).to eq("Updated actions")
    end

    it "does not update the indicator, target, or statement" do
      original_indicator = dr_rai_action_plan.dr_rai_indicator
      original_target = dr_rai_action_plan.dr_rai_target
      other_indicator = create(:indicator, type: "DrRai::TitrationIndicator")
      other_target = create(:target, :percentage, indicator: other_indicator)

      patch :update, params: {
        id: dr_rai_action_plan.to_param,
        dr_rai_action_plan: {
          actions: "Updated actions",
          dr_rai_indicator_id: other_indicator.id,
          dr_rai_target_id: other_target.id,
          statement: "Updated statement"
        }
      }

      dr_rai_action_plan.reload
      expect(dr_rai_action_plan.dr_rai_indicator_id).to eq(original_indicator.id)
      expect(dr_rai_action_plan.dr_rai_target_id).to eq(original_target.id)
      expect(dr_rai_action_plan.statement).to eq("Original statement")
    end

    it "returns no content so the AJAX client can reload the report" do
      patch :update, params: {
        id: dr_rai_action_plan.to_param,
        dr_rai_action_plan: {actions: "Updated actions"}
      }

      expect(response).to have_http_status(:no_content)
    end

    it "returns JSON errors when the update fails validation" do
      dr_rai_action_plan.errors.add(:actions, "is invalid")
      allow(DrRai::ActionPlan).to receive(:find).and_return(dr_rai_action_plan)
      allow(dr_rai_action_plan).to receive(:update).and_return(false)

      patch :update, params: {
        id: dr_rai_action_plan.to_param,
        dr_rai_action_plan: {actions: "Invalid actions"}
      }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body).to eq("actions" => ["is invalid"])
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
