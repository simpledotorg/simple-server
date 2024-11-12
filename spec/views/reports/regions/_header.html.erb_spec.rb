require "rails_helper"

RSpec.describe "reports/regions/_header.html.erb", type: :view do
  let(:organization) { create(:organization) }
  let(:current_admin) { create(:admin, :manager) }
  let(:organization_region) { create(:region, name: "Organization", region_type: "organization", path: "organization") }
  let(:current_period) { Period.current }
  let(:sub_region) { create(:region, name: "State Subregion", region_type: "state", path: "organization.state") }

  helper do
    def accessible_region?(*args)
      true
    end

    def active_action?(*args)
      false
    end
  end

  before do
    allow(view).to receive(:accessible_region?).and_return(true)
    assign(:period, current_period)
    assign(:region, organization_region)

    allow(view).to receive(:params).and_return({report_scope: "organization", id: organization_region.slug})
    allow(view).to receive(:action_name).and_return("diabetes")
    allow(current_admin).to receive(:feature_enabled?).with(:organization_reports).and_return(true)
  end

  describe "when the feature flag for organization_reports is enabled" do
    context "and we are on the organization-level report" do
      it "renders the organization name in the breadcrumb without a hyperlink" do
        render partial: "reports/regions/header", locals: {current_admin: current_admin}
        expect(rendered).to have_link("All reports", href: "/dashboard/districts")
        expect(rendered).not_to have_link("Organization", href: "/reports/regions/organization/organization")
        expect(rendered).to have_content(/Organization/)
      end
    end

    context "when the feature flag for organization_reports is enabled and we are on a sub-level report (e.g., state or facility)" do
      before do
        assign(:region, sub_region)
        assign(:organization, organization)
        allow(view).to receive(:params).and_return({report_scope: "state", id: sub_region.slug})
        allow(current_admin).to receive(:feature_enabled?).with(:monthly_state_data_download).and_return(true)
      end

      it "renders the organization name as a hyperlink in the breadcrumb" do
        render partial: "reports/regions/header", locals: {current_admin: current_admin}
        expect(rendered).to have_link("All reports", href: "/dashboard/districts")
        expect(rendered).to have_link("Organization", href: "/reports/regions/organization/organization")
        expect(rendered).to have_content(/State Subregion/)
      end
    end
  end

  context "when the feature flag for organization_reports is disabled" do
    before do
      allow(current_admin).to receive(:feature_enabled?).with(:organization_reports).and_return(false)
      allow(current_admin).to receive(:feature_enabled?).with(:monthly_state_data_download).and_return(true)
      allow(view).to receive(:params).and_return({report_scope: "state", id: sub_region.slug})
      assign(:region, sub_region)
    end

    it "does not render the organization name in the breadcrumb" do
      render partial: "reports/regions/header", locals: {current_admin: current_admin}
      expect(rendered).to have_link("All reports", href: "/dashboard/districts")
      expect(rendered).not_to have_content("Organization")
    end
  end
end
