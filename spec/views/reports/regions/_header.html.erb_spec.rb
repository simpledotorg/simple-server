require "rails_helper"

RSpec.describe "reports/regions/_header.html.erb", type: :view do
  let(:organization) { create(:organization) }
  let(:current_admin) { create(:admin, :manager) }
  let(:organization_region) { create(:region, name: "Organization", region_type: "organization", path: "organization") }
  let(:facility_region) { create(:region, name: "facility", region_type: "facility", path: "organization.state.district") }
  let(:current_period) { Period.current }

  before do
    inject_controller_helper_methods(Reports::RegionsController, view)

    allow(view).to receive(:accessible_region?).and_return(true)
    assign(:period, current_period)
    assign(:region, organization_region)
    current_admin.accesses.create!(resource: organization)

    allow(view).to receive(:params).and_return({report_scope: "organization", id: organization_region.slug})
    allow(view).to receive(:action_name).and_return("diabetes")
  end

  describe "when the feature flag for organization_reports is enabled" do
    context "and we are on the organization-level report" do
      it "renders the organization name in the breadcrumb without a hyperlink" do
        render partial: "reports/regions/header", locals: {current_admin: current_admin}
        rendered_content = Capybara.string(rendered)
        expect(rendered_content).to have_link("All reports", href: "/dashboard/districts")
        expect(rendered_content).to have_selector("i.fas.fa-chevron-right + span", text: "Organization")
        expect(rendered_content).to have_no_link("Organization", href: "/reports/regions/organization/organization")
      end
    end

    context "when the feature flag for organization_reports is enabled and we are on a sub-level report (e.g., state or facility)" do
      let(:sub_region) { create(:region, name: "State Subregion", region_type: "state", path: "organization.state") }
      it "renders the organization name as a hyperlink in the breadcrumb" do
        render partial: "reports/regions/header", locals: {current_admin: current_admin}
        rendered_content = Capybara.string(rendered)
        expect(rendered_content).to have_link("All reports", href: "/dashboard/districts")
        expect(rendered_content).to have_link("Organization", href: "/reports/regions/organization/organization")
        expect(rendered_content).to have_selector("i.fas.fa-chevron-right + span", text: "State Subregion")
      end
    end
  end

  describe "when the feature flag for organization_reports is disabled" do
    context "when we are on the all reports page" do
      it "does not render the organization name in the breadcrumb" do
        render partial: "reports/regions/header", locals: {current_admin: current_admin}
        rendered_content = Capybara.string(rendered)
        expect(rendered_content).to have_link("All reports", href: "/dashboard/districts")
        expect(rendered_content).to have_no_content("Organization")
      end
    end
  end
end
