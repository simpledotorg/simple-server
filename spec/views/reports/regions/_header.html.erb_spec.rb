require "rails_helper"

RSpec.describe "reports/regions/_header.html.erb", type: :view do
  let(:organization) { create(:organization) }
  let(:current_admin) { create(:admin, :manager) }
  let(:organization_region) { create(:region, name: "Organization", region_type: "organization", path: "organization") }
  let(:organization_region_1) { create(:region, name: "facility", region_type: "facility", path: "organization.state.district") }
  let(:current_period) { Period.current }

  before do
    inject_controller_helper_methods(Reports::RegionsController, view)

    allow(view).to receive(:accessible_region?).and_return(true)
    assign(:period, current_period)
    assign(:region, organization_region)
    current_admin.accesses.create!(resource: organization)

    allow(view).to receive(:params).and_return({report_scope: "organization", id: organization_region.slug})
    allow(view).to receive(:action_name).and_return("diabetes")
    allow(current_admin).to receive(:feature_enabled?).with(:organization_reports).and_return(true)
  end

  describe "when the feature flag for organization_reports is enabled" do
    context "and we are on the organization-level report" do
      it "renders the organization name in the breadcrumb without a hyperlink" do
        render partial: "reports/regions/header", locals: {current_admin: current_admin}
        expect(rendered).to include('<a href="/dashboard/districts">All reports</a>')
        expect(rendered).to match(/<i class="fas fa-chevron-right"><\/i>\s*Organization/)
        expect(rendered).not_to include('<a href="/reports/regions/organization/organization">Organization</a>')
      end
    end

    context "when the feature flag for organization_reports is enabled and we are on a sub-level report (e.g., state or facility)" do
      let(:sub_region) { create(:region, name: "State Subregion", region_type: "state", path: "organization.state") }

      before do
        assign(:region, sub_region)
        assign(:organization, organization)
        allow(view).to receive(:params).and_return({report_scope: "state", id: sub_region.slug})
        allow(current_admin).to receive(:feature_enabled?).with(:monthly_state_data_download).and_return(true)
      end

      it "renders the organization name as a hyperlink in the breadcrumb" do
        render partial: "reports/regions/header", locals: {current_admin: current_admin}
        expect(rendered).to include('<a href="/dashboard/districts">All reports</a>')
        expect(rendered).to include('<a href="/reports/regions/organization/organization">Organization</a>')
        expect(rendered).to match(%r{<i class="fas fa-chevron-right"></i>\s*State Subregion})
      end
    end

    context "when the feature flag for organization_reports is disabled" do
      before do
        allow(current_admin).to receive(:feature_enabled?).with(:organization_reports).and_return(false)
        allow(current_admin).to receive(:feature_enabled?).with(:dashboard_progress_reports).and_return(false)
        allow_any_instance_of(UserAccess).to receive(:can_access?).and_return(true)
        assign(:region, organization_region_1)
      end

      it "does not render the organization name in the breadcrumb" do
        render partial: "reports/regions/header", locals: {current_admin: current_admin}
        expect(rendered).to include('<a href="/dashboard/districts">All reports</a>')
        expect(rendered).not_to include("Organization")
      end
    end
  end
end
