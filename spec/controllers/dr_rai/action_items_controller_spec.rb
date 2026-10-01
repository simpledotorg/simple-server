require "rails_helper"

RSpec.describe DrRai::ActionItemsController, type: :controller do
  let(:district_with_facilities) { setup_district_with_facilities }
  let(:facility) { district_with_facilities[:facility_1] }
  let(:indicator) { create(:indicator, :contact_overdue_patients) }
  let(:action_plan) do
    create(
      :action_plan,
      region: facility.region,
      dr_rai_indicator: indicator,
      dr_rai_target: create(:target, :percentage, period: "Q2-2025", indicator: indicator),
      actions: "Email lead doctors"
    )
  end
  let(:action_item) { action_plan.action_items.first }

  before do
    admin = FactoryBot.create(:admin, :power_user)
    sign_in admin.email_authentication
  end

  describe "PATCH /update" do
    it "marks a task complete and clears it again" do
      Timecop.freeze(Time.zone.parse("June 30 2025 15:12")) do
        patch :update, params: {id: action_item.id, completed: true}

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["completed"]).to eq(true)
        expect(action_item.reload.completed_at).to be_present

        patch :update, params: {id: action_item.id, completed: false}

        expect(action_item.reload.completed_at).to be_nil
        expect(response.parsed_body["completed"]).to eq(false)
      end
    end

    it "allows completion on the last day of the quarter" do
      Timecop.freeze(Time.zone.parse("June 30 2025 15:12")) do
        patch :update, params: {id: action_item.id, completed: true}
        expect(response).to have_http_status(:ok)
      end
    end

    it "allows completion one month after the quarter ends" do
      Timecop.freeze(Time.zone.parse("July 31 2025 15:12")) do
        patch :update, params: {id: action_item.id, completed: true}
        expect(response).to have_http_status(:ok)
        expect(action_item.reload).to be_completed
      end
    end

    it "rejects completion the day after that" do
      Timecop.freeze(Time.zone.parse("August 1 2025 15:12")) do
        patch :update, params: {id: action_item.id, completed: true}
        expect(response).to have_http_status(:forbidden)
        expect(action_item.reload.completed_at).to be_nil
      end
    end

    it "does not allow an admin without report access to the facility to update it" do
      inaccessible_facility = create(:facility)
      admin = create(:admin, :viewer_reports_only, :with_access, resource: inaccessible_facility)
      sign_in admin.email_authentication

      Timecop.freeze(Time.zone.parse("June 30 2025 15:12")) do
        patch :update, params: {id: action_item.id, completed: true}
      end

      expect(action_item.reload.completed_at).to be_nil
      expect(flash[:alert]).to eq("You are not authorized to perform this action.")
    end
  end
end
